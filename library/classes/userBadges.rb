require 'fox16'
require 'yaml'
include Fox

require_relative 'badgeInfoDisplay'

class BadgeDisplay < FXDialogBox
  def initialize(owner, currentUser, characterIcons, characterPicturePath, guiIcons, badgesPath)
    userStoreWindow = super(owner, "User Badges", DECOR_ALL|DECOR_BORDER, :width => 1500, :height => 750)

    @user = currentUser

    #Add character image
    characterFrame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X)

    characterLogo = FXPNGImage.new(getApp(), File.open(characterPicturePath + "/" + @user["user_character"].capitalize + ".png", "rb").read, :opts => IMAGE_KEEP)
    characterLogo.scale(75, 75)
    characterImage = FXImageFrame.new(characterFrame, characterLogo, LAYOUT_SIDE_TOP)
    characterImage.image = characterLogo

    #Add window title
    FXLabel.new(characterFrame, @user["user_name"].capitalize + "'s Badges", :opts => LAYOUT_FILL_Y|JUSTIFY_LEFT|JUSTIFY_BOTTOM).setFont(FXFont.new(getApp(), "helvetica", 24, FONTWEIGHT_BOLD,FONTSLANT_ITALIC, FONTENCODING_DEFAULT))

    FXHorizontalSeparator.new(self)
    badgeFrame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

    badges = loadBadges(badgesPath, badgeFrame)
    if(!badges.empty?)
      badgeScrollArea = FXScrollWindow.new(badgeFrame, :opts => SCROLLERS_TRACK|HSCROLLER_NEVER|LAYOUT_FILL_X|LAYOUT_FILL_Y)
      badgesFrame = FXVerticalFrame.new(badgeScrollArea, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

      arrayIndex = 0
      loopNum = 5 #The number of items in a row
      currentFrame = nil
      badges.each do |badge|
        if((arrayIndex % loopNum) == 0)
          currentFrame = FXHorizontalFrame.new(badgesFrame, :opts => LAYOUT_FILL_X)
        end
        buttonString = badge["badge_description_short"]
        if(badge["badge_icon"] != nil)
          buttonIcon = makeIcon(badgesPath + '/icons/' + badge["badge_icon"])
        else
          buttonIcon = makeIcon(badgesPath + '/icons/bronzeBadge.png')
        end
        currentButton = FXButton.new(currentFrame, buttonString, :icon => buttonIcon, :opts => FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_Y|ICON_ABOVE_TEXT, :height => 150)
        currentButton.connect(SEL_COMMAND) do |sender, selector, event|
          currentBadgeRowChildren = sender.parent.children
          buttonNum = 0
          currentBadgeRowChildren.each do |badgeButton|
            if(badgeButton == sender)
              #Found button at buttonNum index in the array
              badgeSelected = badges[buttonNum]
              if(badgeSelected["badge_icon"] != nil)
                buttonInfoIcon = File.open(badgesPath + '/icons/' + badgeSelected["badge_icon"], "rb").read
              else
                buttonInfoIcon = File.open(badgesPath + '/icons/bronzeBadge.png', "rb").read
              end
              badgesInfoWindow = BadgeInfoDisplay.new(self, badgeSelected, buttonInfoIcon).execute
            end
            buttonNum = buttonNum + 1
          end
        end
        arrayIndex += 1
      end
    end
  end

  def loadBadges(badgesPath, badgeFrame)
    badgeArray = Array.new
    if(File.exist?(badgesPath))
      allBadges = Dir.glob(badgesPath + '/*').select{ |e| File.file? e }
      if(allBadges.length <= 0)
            FXLabel.new(badgeFrame, "No badges currently exist")
      else
        allBadges.each do |file|
          currentFile = YAML.load(File.read(badgesPath + "/" + File.basename(file)))
          badgeArray.push(currentFile)
        end
      end
    end

    return badgeArray
  end

  def makeIcon(filename)
    begin
      icon = nil
      File.open(filename, "rb") do |f|
        icon = FXPNGIcon.new(getApp(), f.read)
      end
      icon.create()
      icon
    rescue
      raise RuntimeError, "Couldn't load icon: #{filename}"
    end
  end
end
