require 'fox16'
include Fox

class EditUserDialog < FXDialogBox
	attr_accessor :newUserName

	def initialize(owner, currentUser)
		super(owner, "Edit User", DECOR_TITLE|DECOR_BORDER)

		@newUserName = FXTextField.new(self, 50)
		@newUserName.text = currentUser["user_name"]

		buttons = FXHorizontalFrame.new(self, :opts => FRAME_NONE|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH)

		FXButton.new(buttons, "Accept", :icon => nil, :target => self, :selector => ID_ACCEPT, :opts => FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
		FXButton.new(buttons, "Cancel", :icon => nil, :target => self, :selector => ID_CANCEL, :opts => FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
	end
end
