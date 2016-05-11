require 'fox16'
require 'yaml'
include Fox

class BadgeInfoDisplay < FXDialogBox
  def initialize(owner, badgeInfo, badgeIcon)
    userStoreWindow = super(owner, "Badge Information", DECOR_ALL|DECOR_BORDER, :width => 1500, :height => 750)

    badgeInfoFrame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X)
    badgeLogo = FXPNGImage.new(getApp(), badgeIcon, :opts => IMAGE_KEEP)
    badgeLogo.scale(75, 75)
    badgeImage = FXImageFrame.new(badgeInfoFrame, badgeLogo, LAYOUT_SIDE_TOP)
    badgeImage.image = badgeLogo

    badgeName = FXLabel.new(badgeInfoFrame, badgeInfo["badge_name"]).setFont(FXFont.new(getApp(), "helvetica", 16, FONTWEIGHT_BOLD,FONTSLANT_ITALIC, FONTENCODING_DEFAULT))
    badgeName = FXLabel.new(badgeInfoFrame, badgeInfo["badge_description"])
  end
end
