module PlaysHelper
  def unstar_link(play)
    link_to image_tag('starred.png', :alt => 'starred - remove', :title => 'You have starred this play. (Click to undo.)', :class => 'play_star_icon'),
      play_star_path(play), :method => :delete, :class => 'star_' + play.id.to_s, :remote => true
  end

  def star_link(play)
    link_to image_tag('unstarred.png', :alt => 'not starred - add', :title => 'Click to star this play.', :class => 'play_star_icon'),
      play_star_path(play), :method => :post, :class => 'star_' + play.id.to_s, :remote => true
  end
end