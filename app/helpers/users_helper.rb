module UsersHelper
  def unfriend_link(user_id)
    link_to image_tag('starred.png', :alt => 'friend - remove', :title => 'This person is a friend of yours.', :class => 'play_icon'),
      unfriend_user_path(user_id), :method => :post, :class => 'friend_' + user_id.to_s, :remote => true
  end

  def friend_link(user_id)
    link_to image_tag('unstarred.png', :alt => 'not friend - add', :title => 'This person is not a friend of yours.', :class => 'play_icon'),
      friend_user_path(user_id), :method => :post, :class => 'friend_' + user_id.to_s, :remote => true
  end

  def unblock_link(user_id)
    link_to 'Unblock', unblock_user_path(user_id), :method => :post, :class => 'block_' + user_id.to_s, :remote => true
  end

  def block_link(user_id)
    link_to 'Block', block_user_path(user_id), :method => :post, :class => 'block_' + user_id.to_s, :remote => true
  end
end
