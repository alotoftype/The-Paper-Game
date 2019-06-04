class Game < ActiveRecord::Base
  has_many :players, :autosave => true
  has_many :users, :through => :players
  has_many :sequences, :autosave => true
  has_many :plays, :through => :sequences
  has_many :game_messages
  has_many :invitations
  validates_numericality_of :round_limit, :odd => true
  validates_numericality_of :player_limit, :only_integer => true
  validates_numericality_of :player_colors_seed, :only_integer => true
  validates_length_of :name, :in => 4..50
  validate :respect_player_limit, :exactly_one_creator
  before_validation :generate_player_colors_seed

  # Helper Sets

  def active_players
    self.players.where(:is_ejected => false)
  end

  def self.open
    where('games.started_at' => nil).
      where(
        '(
          SELECT COUNT("players"."id")
            FROM "players"
            WHERE "players"."game_id" = "games"."id" AND "players"."is_ejected" = \'f\'
        ) < "games"."player_limit"')
  end

  scope :with_friend_count, lambda { |user|
    if user
      return select('games.*,
        (SELECT COUNT (*) FROM players JOIN friends ON friends.friend_user_id = players.user_id AND friends.user_id = %{user_id} WHERE players.game_id = games.id AND NOT EXISTS (SELECT NULL FROM blocks WHERE blocks.blocked_user_id = %{user_id} AND blocks.user_id = friends.friend_user_id)) AS friend_count,
        (SELECT COUNT (*) FROM players JOIN sequences ON sequences.player_id = players.id WHERE players.game_id = games.id AND players.user_id = %{user_id}) AS play_count' %
        {:user_id => user.id})
    else
      return select('games.*, 0 AS friend_count, 0 AS play_count')
    end
  }

  # Accessible Collections

  scope :can_index, lambda { |user|
    where('NOT EXISTS (SELECT NULL FROM blocks JOIN users ON users.id = blocks.blocked_user_id JOIN players ON players.user_id = users.id WHERE players.game_id = games.id AND blocks.user_id = %{user_id})' % { :user_id => user.id })
  }

  def self.can_update(user)
    if user
      return where(
        'EXISTS (SELECT NULL FROM players WHERE players.game_id = games.id AND players.user_id = %{user_id} AND players.is_creator = \'t\')' %
          {:user_id => user.id}
        )
    end
    return where("0 = 1")
  end

  def self.can_edit(user)
    can_update(user)
  end

  def self.can_start(user)
    can_update(user)
  end

  def self.can_destroy(user)
    can_update(user)
  end

  def self.can_show(user)
    if user
      return where(
        'games.is_private = \'f\' AND games.started_at IS NULL
          OR EXISTS (SELECT NULL FROM players WHERE players.game_id = games.id AND players.user_id = %{user_id})
          OR (
            EXISTS (SELECT NULL FROM invitations WHERE
              invitations.game_id = games.id AND invitations.invitee_user_id = %{user_id}
              AND invitations.has_accepted IS NULL)
            AND games.started_at IS NULL
            AND (SELECT COUNT(NULL) FROM players WHERE players.game_id = games.id AND players.is_ejected = \'f\') < games.player_limit
          )' %
          {:user_id => user.id}
        )
    end
    return where(:is_private => false, :started_at => nil)
  end

  def self.can_join(user)
    if user
      return open.
        where('NOT EXISTS (SELECT NULL FROM players WHERE players.game_id = games.id AND players.user_id = %{user_id})' % {:user_id => user.id})
    end
    return where('0 = 1')
  end

  def self.can_leave(user)
    if user
      return where("EXISTS (SELECT NULL FROM players WHERE players.game_id = games.id AND players.user_id = %{user_id} AND players.is_ejected = 'f' AND players.is_creator = 'f')" % {:user_id => user.id})
    end
    return where('0 = 1')
  end

  def self.can_index(user)
    if user
      return can_join(user)
    end
    return can_show(user)
  end

  # Collection Access

  def self.can_index?(user)
    true
  end

  def self.can_create?(user)
    if user then true else false
    end
  end

  def self.can_new?(user)
    can_create?(user)
  end

  # Instance Access

  def can_show?(user)
    Game.can_show(user).exists?(self)
  end

  def can_show_user_token?(user)
    return false if user == nil
    games = Game.where{|g| g.id == self.id}
    GameUserTokenAuthorization.can_show(user, games).exists?
  end

  def can_join?(user)
    Game.can_join(user).exists?(self)
  end

  def can_leave?(user)
    Game.can_leave(user).exists?(self)
  end

  def can_update?(user)
    Game.can_update(user).exists?(self)
  end

  def can_edit?(user)
    Game.can_edit(user).exists?(self)
  end

  def can_start?(user)
    Game.can_start(user).exists?(self)
  end

  def can_destroy?(user)
    Game.can_destroy(user).exists?(self)
  end

  def can_create?(user)
    Game.can_create?(user)
  end

  def can_new?(user)
    Game.can_new?(user)
  end

  def can_invite?(user)
    !self.is_private? || self.is_open_invitation? || self.players.where{players.user_id == user.id}.where{players.is_creator == true}.exists?
  end
  
  # Helper Properties

  def spots_remaining
    self.player_limit - self.active_players.count
  end

  def game_events_path
    '/games/' + id.to_s + '/messages'
  end
  
  def top_sentences(user)
    Play.find_by_sql(
      'SELECT
          p.id, p.sentence, p.picture_id, u.login, ps.id AS star_id, pr.id AS player_id, p.position, CASE WHEN u.id = %{user_id} THEN NULL ELSE 1 END AS "user_can_star", sc.star_count
        FROM
          plays p
          LEFT JOIN (SELECT COUNT(*) AS star_count, play_id FROM play_stars GROUP BY play_id) AS sc ON sc.play_id = p.id
          JOIN sequences s ON s.id = p.sequence_id
          JOIN players pr ON pr.id = p.player_id
          JOIN users u ON u.id = pr.user_id
          LEFT JOIN play_stars ps ON ps.play_id = p.id AND ps.user_id = %{user_id}
        WHERE
          s.game_id = %{game_id}
          AND sentence IS NOT NULL
        ORDER BY
          sc.star_count IS NULL,
          sc.star_count DESC,
          random()
        LIMIT 3' %
      {:game_id => self.id, :user_id => user.id})
  end
  
  def top_pictures(user)
    Play.find_by_sql(
      'SELECT
          p.id, p.sentence, p.picture_id, u.login, ps.id AS star_id, pr.id AS player_id, p.position, CASE WHEN u.id = %{user_id} THEN NULL ELSE 1 END AS "user_can_star", sc.star_count
        FROM
          plays p
          LEFT JOIN (SELECT COUNT(*) AS star_count, play_id FROM play_stars GROUP BY play_id) AS sc ON sc.play_id = p.id
          JOIN sequences s ON s.id = p.sequence_id
          JOIN players pr ON pr.id = p.player_id
          JOIN users u ON u.id = pr.user_id
          LEFT JOIN play_stars ps ON ps.play_id = p.id AND ps.user_id = %{user_id}
        WHERE
          s.game_id = %{game_id}
          AND sentence IS NULL
        ORDER BY
          sc.star_count IS NULL,
          sc.star_count DESC,
          random()
        LIMIT 3' %
      {:game_id => self.id, :user_id => user.id})
  end
  
  def sequence_by_user(user)
    self.sequences.
      joins{ plays.player }.
      where{ plays.position == 1 }.
      where{ |s| s.players.user_id == user.id }.
      first.position
  end

  def player_colors
    generate_player_colors_seed
    Game.player_colors_from_seed(player_colors_seed)
  end

  def player_color(position)
    self.player_colors[position - 1 % 19]
  end

  def self.player_colors_from_seed(seed)
    # The seed should be a number from 0 to 341.
    # This function turns the seed into a random even cycle of the multiples of 19 less than 19 * 19 = 361.
    # Why is he seed 0 to 341? 361 = 0 in mod 361, and so is not an interesting seed, nor is anything after it.
    # 342 to 360 should otherwise be a valid seeds, but then step = 19, and cycling by a number of steps that shares
    # a common factor with the cycle length essentially "factors out" the possible outcomes.
    # Why 19? You could actually do this with any prime, but you'd have to scale the output to 360 afterward.
    # Isn't it great that 360 is very nearly the square of a prime?
    start = seed % 19
    step = seed / 19 + 1
    (0..18).collect { |i| ( start + step * i) % 19 * 19  }
  end

  def player(user)
    return nil if !user
    player = Player.find_by_sql(
      %[SELECT
          p.*,
          r.plays_remaining
        FROM
          players p
          LEFT JOIN (
            SELECT
                p.id as player_id,
                SUM((g.round_limit - s.plays_made) / g.player_count + ((g.round_limit - s.plays_made) %% g.player_count - (p.compacted_position - s.compacted_position + g.player_count) %% g.player_count + g.player_count - 1) / g.player_count) AS plays_remaining
              FROM
                (SELECT p.*, (SELECT COUNT(*) FROM players p2 WHERE p2.game_id = p.game_id AND p2.position <= p.position AND p2.is_ejected = 'f') AS compacted_position FROM players p) p
                JOIN (SELECT g.id, g.round_limit, COUNT(*) AS player_count FROM games g JOIN players p ON p.game_id = g.id WHERE p.is_ejected = 'f' GROUP BY g.id, g.round_limit) g ON g.id = p.game_id
                JOIN (
                  SELECT
                      s.game_id, COALESCE(pm.plays_made, 0) AS plays_made, pr.compacted_position
                    FROM
                      sequences s
                      JOIN (SELECT pr.id, (SELECT COUNT(*) FROM players pr2 WHERE pr2.game_id = pr.game_id AND pr2.position <= pr.position AND pr2.is_ejected = 'f') AS compacted_position  FROM players pr) pr ON pr.id = s.player_id
                      LEFT JOIN (SELECT p.sequence_id, COUNT(*) AS plays_made FROM plays p GROUP BY p.sequence_id) pm ON pm.sequence_id = s.id
                ) s ON s.game_id = p.game_id
              GROUP BY
                p.id
          ) r ON r.player_id = p.id
        WHERE
          p.user_id = %{user_id} AND p.game_id = %{game_id}
    ] % {:user_id => user.id, :game_id => self.id}).
    first
    player.plays_remaining = player.plays_remaining.to_i if (player.plays_remaining)
    return player
  end

  def estimated_current_round
    (self.sequences.joins{plays}.maximum('plays.position') || 0) + 1
  end

  def creator=(user)
    self.players.build(:user => user, :is_creator => true, :game => self, :position => 1)
  end

  def creator
    self.players.where(:is_creator => true).first.user
  end

  def is_full?
    self.users.count >= player_limit
  end

  def has_started?
    started_at?
  end

  def has_ended?
    ended_at?
  end
  
  def next_player_position
    self.players.where(:game_id => self.id).maximum(:position) + 1
  end

  # Mutating Methods

  def start(shuffle_players = true)
    Game.transaction do
      if has_started?
        errors.add(:base, 'This game has already begun.')
        return
      end
      self.started_at = DateTime.now
      delete_ejected_players
      randomize_player_positions if (shuffle_players)
      start_sequences
      save!
    end
  end

  def add_player(user)
    if has_started?
      errors.add(:base, 'This game has already begun.')
      return
    end
    player = self.players.build(:user => user, :game => self)
    if self.save
      self.game_messages.where{ |m| m.user_id == user.id }.update_all :player_id => player.id
      return player
    end
    return false
  end

  def check_if_finished
    if finished?
      self.ended_at = DateTime.now
      self.players.where{is_ejected == false}.each do |player|
        Notifier.game_complete(self, player.user).deliver
      end
    end
  end

  private

  def delete_ejected_players
    self.players.where(:is_ejected => true).each do |player|
      player.delete
    end
  end

  def randomize_player_positions
    random_players = self.players.shuffle
    position = next_player_position
    random_players.each do |random_player|
      random_player.position = position
      position = position + 1
    end
  end

  # Miscellaneous Helpers

  def generate_player_colors_seed
    # 19 * 18 = 342
    self.player_colors_seed = rand(342) unless self.player_colors_seed
  end

  def start_sequences
    self.players.each_with_index do |player, position|
      self.sequences.build(:game => self, :player => player, :queue_position => 1, :position => position + 1 )
    end
  end

  def finished?
    !self.sequences.where('(SELECT COUNT("plays"."id") FROM "plays" WHERE "plays"."sequence_id" = "sequences"."id") < ?', self.round_limit).any?
  end

  # Validation

  def respect_player_limit
    if self.players.count > self.player_limit && self.player_limit_changed?
      errors.add(:base, 'There are already more players than that.')
      return
    end
    errors.add(:base, 'This game is already full.') if self.players.count > self.player_limit
  end

	def exactly_one_creator
	  creator_count = self.players.find_all{ |player| player.is_creator }.size
    errors.add(:base, 'A game can only have one creator.') if creator_count > 1
    errors.add(:base, 'A game must have a creator.') if creator_count == 0
	end
end

