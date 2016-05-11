require 'fox16'
include Fox

class AvatarCustomisation < FXDialogBox
  def initialize(owner, currentUser, characterIcons)
    editUserWindow = super(owner, "Edit User", DECOR_ALL|DECOR_BORDER, :width => 750, :height => 750)
  end
end
