require 'fox16'
include Fox

class EditUserDialog < FXDialogBox
	attr_accessor :newUserName
  attr_accessor :deleteUser
  attr_accessor :newUserCurrency

	def initialize(owner, currentUser, characterIcons)
		editUserWindow = super(owner, "Edit User", DECOR_TITLE|DECOR_BORDER, :width => 500, :height => 500)

		@newUserName = FXTextField.new(self, 50)
		@newUserName.text = currentUser["user_name"]

    characterSelectionArea = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X)
    characterSelectionScrollArea = FXScrollArea.new(characterSelectionArea, :opts => SCROLLERS_TRACK|VSCROLLER_NEVER|HSCROLLER_ALWAYS|LAYOUT_FILL_X|LAYOUT_FILL_Y, :height => 70)

    characterIcons.each do |characterName, characterIcon|
      FXImageFrame.new(characterSelectionScrollArea, FXPNGImage.new(getApp(), File.open("characterPictures/" + characterName + ".png", "rb").read, :opts => IMAGE_KEEP|LAYOUT_FILL_Y))
    end

    characterSelectionArea.recalc
    characterSelectionScrollArea.recalc

    @deleteUser = FXCheckButton.new(self, "Delete User:", nil, 0, ICON_AFTER_TEXT|LAYOUT_SIDE_TOP)

		buttons = FXHorizontalFrame.new(self, :opts => FRAME_NONE|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH)

    acceptButton = FXButton.new(buttons, "Accept Edit")
    acceptButton.connect(SEL_COMMAND) do |sender, selector, ptr|
      editUserWindow.handle(self, FXSEL(SEL_COMMAND, FXDialogBox::ID_ACCEPT), nil)
    end

    acceptButton = FXButton.new(buttons, "Cancel Edit")
    acceptButton.connect(SEL_COMMAND) do |sender, selector, ptr|
      editUserWindow.handle(self, FXSEL(SEL_COMMAND, FXDialogBox::ID_CANCEL), nil)
    end


	end
end
