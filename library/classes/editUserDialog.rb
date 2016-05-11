require 'fox16'
include Fox

class EditUserDialog < FXDialogBox
	attr_accessor :newUserName
  attr_accessor :deleteUser
  attr_accessor :newUserCharacter

	def initialize(owner, currentUser, characterIcons)
		editUserWindow = super(owner, "Edit User", DECOR_ALL|DECOR_BORDER, :width => 1500, :height => 750)

		userNameField = FXTextField.new(self, 50)
		userNameField.text = currentUser["user_name"]


    characterSelectionScrollArea = FXScrollWindow.new(self, :opts => SCROLLERS_TRACK|HSCROLLER_ALWAYS|VSCROLLER_NEVER|LAYOUT_FILL_X|LAYOUT_FIX_HEIGHT, :height => 100)
    characterSelectionArea = FXHorizontalFrame.new(characterSelectionScrollArea, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

    characterIcons.each do |characterName, characterIcon|
      if(characterIcon != nil)
        currentButton = FXButton.new(characterSelectionArea, "", :icon => characterIcon, :width => 50)
      else
        currentButton = FXButton.new(characterSelectionArea, characterName, :icon => nil, :width => 50)
      end

      currentButton.connect(SEL_COMMAND) do |sender, selector, ptr|
        if(sender.icon == characterIcon)
          @newUserCharacter = characterName
        end
      end
    end

    deleteUserField = FXCheckButton.new(self, "Delete User:", nil, 0, ICON_AFTER_TEXT|LAYOUT_SIDE_TOP)

		buttons = FXHorizontalFrame.new(self, :opts => FRAME_NONE|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH)

    acceptButton = FXButton.new(buttons, "Accept Edit")
    acceptButton.connect(SEL_COMMAND) do |sender, selector, ptr|
      userAccept = true
      if(@newUserCharacter != nil && currentUser["user_character"] != @newUserCharacter)
        userResponse = FXMessageBox.new(self, "Confirm User Changes", "You have made changes that will overwrite any current progress, do you want to proceed?", :opts => MBOX_OK_CANCEL)
        if(userResponse.execute == 4)
          userAccept = false
        end
      else
        @newUserCharacter = currentUser["user_character"]
      end

      if(userAccept)
        @newUserName = userNameField.text
        @deleteUser = deleteUserField.checked?
        editUserWindow.handle(self, FXSEL(SEL_COMMAND, FXDialogBox::ID_ACCEPT), nil)
      end
    end

    acceptButton = FXButton.new(buttons, "Cancel Edit")
    acceptButton.connect(SEL_COMMAND) do |sender, selector, ptr|
      editUserWindow.handle(self, FXSEL(SEL_COMMAND, FXDialogBox::ID_CANCEL), nil)
    end


	end
end
