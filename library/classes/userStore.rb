require 'fox16'
require 'yaml'
include Fox

class AvatarStore < FXDialogBox
  attr_accessor :user

  def initialize(owner, currentUser, characterIcons, characterPicturePath, guiIcons, itemsPath)
    userStoreWindow = super(owner, "Avatar Store", DECOR_ALL|DECOR_BORDER, :width => 1500, :height => 750)

    @user = currentUser

    #Add character image
    characterFrame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X)

    characterLogo = FXPNGImage.new(getApp(), File.open(characterPicturePath + "/" + @user["user_character"] + ".png", "rb").read, :opts => IMAGE_KEEP)
    characterLogo.scale(75, 75)
    characterImage = FXImageFrame.new(characterFrame, characterLogo, LAYOUT_SIDE_TOP)
    characterImage.image = characterLogo

    #Add window title
    FXLabel.new(characterFrame, @user["user_character"].capitalize + "'s Store", :opts => LAYOUT_FILL_Y|JUSTIFY_LEFT|JUSTIFY_BOTTOM).setFont(FXFont.new(getApp(), "helvetica", 24, FONTWEIGHT_BOLD,FONTSLANT_ITALIC, FONTENCODING_DEFAULT))

    playerPoints = FXHorizontalFrame.new(characterFrame, :opts => LAYOUT_FILL_Y|LAYOUT_FILL_X)
    #Add user's abilityPoints
    FXLabel.new(playerPoints, "Ability Points: " + @user["user_abilityPoints"].to_s, :icon => guiIcons["abilityPoints"], :opts => LAYOUT_FILL_Y|TEXT_AFTER_ICON|JUSTIFY_BOTTOM|LAYOUT_RIGHT)
    #Add user's currency
    FXLabel.new(playerPoints, "Currency: " + @user["user_currency"].to_s, :icon => guiIcons["currency"], :opts => LAYOUT_FILL_Y|TEXT_AFTER_ICON|JUSTIFY_BOTTOM|LAYOUT_RIGHT)

    FXHorizontalSeparator.new(self)
    itemFrame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

    loadItems(itemFrame, itemsPath, userStoreWindow)

    puts "adding closing statement"
    userStoreWindow.connect(SEL_CLOSE) do
      puts "closing store"
    end

    userStoreWindow.connect(FXSEL(SEL_COMMAND, FXDialogBox::ID_ACCEPT)) do
        puts "closing store"
    end
  end

  def loadItems(itemFrame, itemsPath, window)
    if(File.exist?(itemsPath))
        #Find out how many items there are currently
        allItems = Dir.glob(itemsPath + '/*').select{ |e| File.file? e }
        if(allItems.length <= 0)
            FXLabel.new(itemFrame, "No items currently exists to purchase")
        else
            itemWeapons = Array.new
            itemArmours = Array.new
            itemMiscs = Array.new

            #Load each item and put it into the correct category
            allItems.each do |file|
                currentFile = YAML.load(File.read(itemsPath + "/" + File.basename(file)))
                if(currentFile["item_type"] == "weapon")
                    itemWeapons.push(currentFile)
                elsif(currentFile["item_type"] == "armour")
                    itemArmours.push(currentFile)
                else
                    itemMiscs.push(currentFile)
                end
            end

            displayWeapons(itemFrame, itemWeapons, window)
            FXHorizontalSeparator.new(itemFrame)
            displayArmours(itemFrame, itemArmours)
            FXHorizontalSeparator.new(itemFrame)
            displayMiscItems(itemFrame, itemMiscs)
        end
    else
        puts "Could not find the item directory"
    end
  end

  def displayWeapons(itemFrame, weapons, window)

    FXLabel.new(itemFrame, "Available Weapons")
    weaponScrollArea = FXScrollWindow.new(itemFrame, :opts => SCROLLERS_TRACK|VSCROLLER_NEVER|LAYOUT_FILL_X|LAYOUT_FIX_HEIGHT, :height => 75)
    weaponSelectionArea = FXHorizontalFrame.new(weaponScrollArea, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

    weapons.each do |weapon|
        if(!checkUserHasItem(weapon))
            buttonString = weapon["item_name"] + "\n" + weapon["stats"]["attack"].to_s + "/" + weapon["stats"]["defense"].to_s + "\n Price: " + weapon["price"].to_s
            currentButton = FXButton.new(weaponSelectionArea, buttonString, :opts => BUTTON_NORMAL|LAYOUT_FIX_HEIGHT, :height => 50)
            currentButton.connect(SEL_COMMAND) do |sender, selector, event|
                weaponFrame = sender.parent
                weaponFrameChildren = sender.parent.children
                buttonNum = 0
                weaponFrameChildren.each do |weaponButton|
                    if(weaponButton == sender)
                        #Found button at buttonNum index in the array
                        @user["user_items"].push(weapons[buttonNum])
                        window.handle(self, FXSEL(SEL_COMMAND, FXDialogBox::ID_ACCEPT), nil)
                    end
                    buttonNum = buttonNum + 1
                end
            end
        end
    end
  end

  def displayArmours(itemFrame, armours)

    FXLabel.new(itemFrame, "Available Armours")
    armourScrollArea = FXScrollWindow.new(itemFrame, :opts => SCROLLERS_TRACK|VSCROLLER_NEVER|LAYOUT_FILL_X|LAYOUT_FIX_HEIGHT, :height => 75)
    armourSelectionArea = FXHorizontalFrame.new(armourScrollArea, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

    armours.each do |armour|
        if(!checkUserHasItem(armour))
            buttonString = armour["item_name"] + "\n" + armour["stats"]["attack"].to_s + "/" + armour["stats"]["defense"].to_s + "\n Price: " + armour["price"].to_s
            currentButton = FXButton.new(armourSelectionArea, buttonString, :opts => BUTTON_NORMAL|LAYOUT_FIX_HEIGHT, :height => 50)
            currentButton.connect(SEL_COMMAND) do |sender, selector, ptr|
                puts ""
            end
        end
    end
  end

  def displayMiscItems(itemFrame, miscs)

    FXLabel.new(itemFrame, "Available Miscellaneous Items")
    miscScrollArea = FXScrollWindow.new(itemFrame, :opts => SCROLLERS_TRACK|VSCROLLER_NEVER|LAYOUT_FILL_X|LAYOUT_FIX_HEIGHT, :height => 75)
    miscSelectionArea = FXHorizontalFrame.new(miscScrollArea, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

    miscs.each do |misc|
        if(!checkUserHasItem(misc))
            buttonString = misc["item_name"] + "\n" + misc["stats"]["attack"].to_s + "/" + misc["stats"]["defense"].to_s + "\n Price: " + misc["price"].to_s
            currentButton = FXButton.new(armourSelectionArea, buttonString, :opts => BUTTON_NORMAL|LAYOUT_FIX_HEIGHT, :height => 50)
            currentButton.connect(SEL_COMMAND) do |sender, selector, ptr|
                puts ""
            end
        end
    end
  end

  def checkUserHasItem(checkItem)
    hasItem = false

    @user["user_items"].each do |userItem|
        if(userItem["item_name"] == checkItem["item_name"])
            hasItem = true
        end
    end

    return hasItem
  end
end
