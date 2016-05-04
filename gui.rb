require 'fox16'
require 'fox16/colors'
require 'tree'
require 'pathname'
require 'yaml'
include Fox

@classesPath = "library/classes"
@iconsPath = "library/icons"
@characterPicturePath = "library/characterPictures"
@usersPath = "library/users"
@itemsPath = "library/items"

require_relative @classesPath + '/editUserDialog'
require_relative @classesPath + '/userStore'

class GUIWindow < FXMainWindow

  @currentIconPath = ""
  @currentUserPath = ""
  @currentCharacterPicturePath = ""
  @currentItemsPath = ""


	def initialize(app, title, width, height, currentIconPath, currentUsersPath, currentCharacterPicturePath, currentItemsPath)
		super(app, title, :opts => DECOR_ALL, :width => width, :height => height)

    @currentIconPath = currentIconPath
    @currentUsersPath = currentUsersPath
    @currentCharacterPicturePath = currentCharacterPicturePath
    @currentItemsPath = currentItemsPath

    @guiIcons = Hash.new
		@guiIcons["icon_folder_open"]   = makeIcon(@currentIconPath + "/minifolderopen.png")
    @guiIcons["icon_folder_closed"] = makeIcon(@currentIconPath + "/minifolder.png")
    @guiIcons["icon_doc"]           = makeIcon(@currentIconPath + "/minidoc.png")
    @guiIcons["currency"]           = makeIcon(@currentIconPath + "/currency.png")
    @guiIcons["abilityPoints"]      = makeIcon(@currentIconPath + "/abilityPoints.png")

    @characterIcons = Hash.new
    createCharacterIcons()

    @directoryHash = Hash.new
    @directoryTree
    @currentLoadedFile = nil

    @users = Array.new

    #Add blank user
    @currentUser = Hash.new

    #------------------------------#
    # ADD USERS FROM SAVE FILE #
    new_users = Array.new
    if(File.exist?(@currentUsersPath))
      if(File.exist?(@currentUsersPath + "/userInfo.yml"))
        new_users = YAML.load(File.read(@currentUsersPath + "/userInfo.yml"))
        if new_users != false
          new_users.each do |new_user|
            @users.push(new_user)
          end
          @currentUser = @users[0]
          @users.each do |user|
            if @currentUser["last_logged"] < user["last_logged"]
              @currentUser = user
            end
          end
        end
      end
    end

    #------------------------------#
    # ADD USER TO CURRENT USER #
    @userExperienceDataTarget = FXDataTarget.new(0)
    @userCurrencyDataTarget = FXDataTarget.new(0)
    @userAbilityPointsDataTarget = FXDataTarget.new(0)
    if(!@currentUser.empty?)
      @userExperienceDataTarget.value = @currentUser["user_experience"].to_i
      @userCurrencyDataTarget.value = @currentUser["user_currency"].to_i
      @userAbilityPointsDataTarget.value = @currentUser["user_abilityPoints"].to_i
    end

		add_menu_bar
		add_status_bar
		add_splitter_area

    self.connect(SEL_CLOSE) do
      on_close
    end
	end

	def create
		super
		show(PLACEMENT_SCREEN)
	end

	private
	def add_menu_bar

		#Create menu bar
		@main_menu_bar = FXMenuBar.new(self, LAYOUT_SIDE_TOP | LAYOUT_FILL_X)

		#Create file menu
    file_menu = FXMenuPane.new(self)
    FXMenuTitle.new(@main_menu_bar, "File", :popupMenu => file_menu)

    #New Command
    new_cmd = FXMenuCommand.new(file_menu, "New")
    new_cmd.connect(SEL_COMMAND) do
      @mainTxt.text = ""
    end

    #Load Commands
    FXMenuSeparator.new(file_menu)

    load_cmd = FXMenuCommand.new(file_menu, "Load File")
    load_cmd.connect(SEL_COMMAND) do
      dialog = FXFileDialog.new(self, "Load a File")
      dialog.selectMode = SELECTFILE_EXISTING
      dialog.patternList = ["*.rb, *.rspec"]
      if dialog.execute != 0
        load_file(dialog.filename)
      end
    end

    load_folder_cmd = FXMenuCommand.new(file_menu, "Load Folder")
    load_folder_cmd.connect(SEL_COMMAND) do
    	dialog = FXDirDialog.new(self, "Load a folder")
    	if dialog.execute != 0
        load_folder(dialog.directory)
      end
    end

    #Save Commands
    FXMenuSeparator.new(file_menu)

    save_cmd = FXMenuCommand.new(file_menu, "Save")
    save_cmd.connect(SEL_COMMAND) do
      dialog = FXFileDialog.getSaveFilename(self, "Save a File", @currentLoadedFile)
      save_file(dialog)
    end

    #Exit Command
    FXMenuSeparator.new(file_menu)

    exit_cmd = FXMenuCommand.new(file_menu, "Exit")
    exit_cmd.connect(SEL_COMMAND) do
      on_close
    end

    #Create user profile menu
    @user_menu = FXMenuPane.new(self)
    FXMenuTitle.new(@main_menu_bar, "Users", :popupMenu => @user_menu)

    create_new_user_cmd = FXMenuCommand.new(@user_menu, "Create a new user")
    create_new_user_cmd.connect(SEL_COMMAND) do
      result = FXInputDialog.getString("",app,"Create New User","Enter a username")
      if result
        is_new_user = true
        @users.each do |user|
          if user["user_name"].downcase == result.downcase
            is_new_user = false
          end
        end

        if is_new_user
          newUser = createNewUserHash(result, nil)
          @users.push(newUser)
          update_current_user(newUser["user_name"])
        end
      end
    end

    @user_select_menu = FXMenuPane.new(@user_menu)
    FXMenuCascade.new(@user_menu, "Select User", :popupMenu => @user_select_menu)

    if @users.length > 0
      @users.each do |user|
        x_select_user = FXMenuCommand.new(@user_select_menu, user["user_name"])
        x_select_user.connect(SEL_COMMAND) do |sender, sel, ptr|
          update_current_user(sender.to_s)
        end
      end
    else
      no_user_exists = FXMenuCommand.new(@user_select_menu, "No Users Exist")
    end

    if !@currentUser.empty?
      select_current_user_cmd = FXMenuCommand.new(@user_menu, "Current User: " + @currentUser["user_name"].to_s)
      select_current_user_cmd.connect(SEL_COMMAND) do |sender, selector, ptr|
        #create edit dialog
        editUser = EditUserDialog.new(self, @currentUser, @characterIcons)
        if editUser.execute != 0
          if(editUser.deleteUser)
            puts "want to delete user"
          else
            if(editUser.newUserCharacter != @currentUser["user_character"])
              @currentUser["user_name"] = editUser.newUserName
              @currentUser["user_character"] = editUser.newUserCharacter
              resetUserProgress()
            else
              @currentUser["user_name"] = editUser.newUserName
              update_current_user(@currentUser["user_name"])
            end
          end
        end
      end

      #FXMenuSeparator.new(menu_bar, LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X|SEPARATOR_GROOVE)

      #Create a button that runs the current test
      @run_menu_command = FXMenuCommand.new(@main_menu_bar, "Run Tests")
      @run_menu_command.connect(SEL_COMMAND) do
        runUserTest()
      end
    end
  end

  def update_current_user(userName)
    if !@currentUser.empty?
      old_user = @currentUser
      @user_menu.removeChild(@user_menu.childAtIndex(2))
    end

    @users.each do |user|
      if user["user_name"] == userName
        @currentUser = user
        @currentUser["last_logged"] = Time.now.utc
      end
    end

    @user_select_menu.children.each do |user_select|
      @user_select_menu.removeChild(user_select)
    end

    @users.each do |user|
      x_select_user = FXMenuCommand.new(@user_select_menu, user["user_name"])
      x_select_user.connect(SEL_COMMAND) do |sender, sel, ptr|
        update_current_user(sender.to_s)
      end
    end

    @user_select_menu.create
    @user_select_menu.recalc

    @gameArea.childAtIndex(0).text = @currentUser["user_name"]

    logo = FXPNGImage.new(getApp(), File.open(@currentCharacterPicturePath + "/"+ @currentUser["user_character"] + ".png", "rb").read, :opts => IMAGE_KEEP)
    logo.scale(174, 174)
    @image.image = logo

    @userExperienceDataTarget.value = @currentUser["user_experience"].to_i
    @userCurrencyDataTarget.value = @currentUser["user_currency"].to_i
    @userAbilityPointsDataTarget.value = @currentUser["user_abilityPoints"].to_i

    select_current_user_cmd = FXMenuCommand.new(@user_menu, "Current User: " + @currentUser["user_name"].to_s)
    select_current_user_cmd.connect(SEL_COMMAND) do |sender, selector, ptr|
      #create edit dialog
      editUser = EditUserDialog.new(self, @currentUser, @characterIcons)
      if editUser.execute != 0
        if(editUser.deleteUser)
          puts "want to delete user"
        else
          if(editUser.newUserCharacter != @currentUser["user_character"])
            @currentUser["user_name"] = editUser.newUserName
            @currentUser["user_character"] = editUser.newUserCharacter
            resetUserProgress()
          else
            @currentUser["user_name"] = editUser.newUserName
            update_current_user(@currentUser["user_name"])
          end
        end
      end
    end

    if(!@run_menu_command)
      #Create a button that runs the current test
      @run_menu_command = FXMenuCommand.new(@main_menu_bar, "Run Tests")
      @run_menu_command.connect(SEL_COMMAND) do
        runUserTest()
      end
    end

    @main_menu_bar.create
    @main_menu_bar.recalc

    @user_menu.create
    @user_menu.recalc

    @gameArea.create
    @gameArea.recalc
  end

  def calculateTestScore(rspecResults, simpleCovResults)
    oldRspecResults = @currentUser["user_lastTestRun"]["user_lastTestResult"]
    oldSimpleCovResults = @currentUser["user_lastTestRun"]["user_lastCoverageResult"]

    currentScore = 0

    if(!oldRspecResults.empty?)
      # Calculate difference in total tests ran
      totalTestsRan = rspecResults[:summary][:example_count]
      ranTestDifference = totalTestsRan - oldRspecResults[:summary][:example_count]
      if(ranTestDifference > 0)
        currentScore += 10
      elsif(ranTestDifference == 0)
        currentScore = currentScore
      else
        currentScore -= 10
      end

      @currentUser["user_lastTestRun"]["user_lastTestResult"] = rspecResults
      @currentUser["user_lastTestRun"]["user_lastCoverageResult"] = simpleCovResults
    else
      @currentUser["user_lastTestRun"]["user_lastTestResult"] = rspecResults
      @currentUser["user_lastTestRun"]["user_lastCoverageResult"] = simpleCovResults
    end

    if(currentScore != 0)
      updateUserScores(currentScore)
    end
  end

  def updateUserScores(score)
    @currentUser["user_experience"] += calculateNewUserExperience(score)
    @currentUser["user_currency"] += calculateNewUserCurrency(score)
    @currentUser["user_abilityPoints"] += calculcateNewUserAbilityPoints(score)

    update_current_user(@currentUser["user_name"])
  end

  def calculateNewUserExperience(score)
    currentExperience = 0.0

    currentExperience = score/20.to_f

    return currentExperience
  end

  def calculateNewUserCurrency(score)
    currentCurrency = 0.0

    currentCurrency = score * 10.to_f

    return currentCurrency
  end

  def calculcateNewUserAbilityPoints(score)
    currentAbilityPoints = 0.0

    currentAbilityPoints = score/10.to_f

    return currentAbilityPoints
  end

  def resetUserProgress()
    @currentUser = createNewUserHash(@currentUser["user_name"], @currentUser["user_character"])
  end

  def runUserTest()
    if(@currentLoadedFile != nil)
      testFile = nil
      if(File.extname(@currentLoadedFile) == ".rb")
        testFile = File.dirname(@currentLoadedFile) + "/" + File.basename(@currentLoadedFile, ".rb") + ".rspec"
      elsif(File.extname(@currentLoadedFile) == ".rspec")
        testFile = @currentLoadedFile
      end

      if(testFile != nil)
        testResult = system 'ruby library/testRunner.rb ' + testFile
        if(testResult)
          if(File.exist?("coverage"))
            if(File.exist?("coverage/rspecResult.yml"))
              # Getting rspec results
              newRspecResults = YAML.load(File.read('coverage/rspecResult.yml'))

              # Getting simplecov results
              newSimpleCovResults = JSON.parse(File.read('coverage/coverage.json'))

              calculateTestScore(newRspecResults, newSimpleCovResults)
            else
              puts "couldn't find rspec result file"
            end
          else
            puts "couldn't find rspec result directory"
          end
        end
      end
    end
  end

  def createNewUserHash(new_user_name, new_user_character)
    if(new_user_character == nil)
      new_user_character = "cando"
    end
    new_user_items = Array.new
    new_user_test_data = Hash["user_lastTestResult", {}, "user_lastCoverageResult", {}]
    new_user = Hash["user_name", new_user_name]
    new_user["user_character"] = new_user_character
    new_user["user_characterHealth"] = 100
    new_user["user_experience"] = 0.0
    new_user["user_currency"] = 0.0
    new_user["user_abilityPoints"] = 0.0
    new_user["user_lastTestRun"] = new_user_test_data
    new_user["user_items"] = new_user_items
    new_user["last_logged"] = Time.now.utc

    return new_user
  end

	def load_file(filename)
    @currentLoadedFile = filename
	  contents = ""

	  if(File.exist?(filename))
		  File.open(filename, 'r') do |f1|
		    while line = f1.gets
		      contents += line
		    end
		  end
		end
	  @mainTxt.text = contents
    addLineNumbers()
	end

	def load_folder(directory)
		Dir.chdir(directory)
		dir = Pathname.new(directory)

		newDirectory(dir, nil)
	end

	def save_file(filename)
		begin
			file = File.new(filename,"wb")
			file.print @mainTxt.text;
			file.close;
			puts "> Saved successfully."
			return true;
		rescue
			puts "> Save Failed: File not found."
			return false
		end

		load_file(filename)
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

  def add_status_bar
  	status = FXStatusBar.new(self, LAYOUT_SIDE_BOTTOM | LAYOUT_FILL_X | STATUSBAR_WITH_DRAGCORNER)
  end

  def add_splitter_area
  	@splitter1 = FXSplitter.new(self, :opts => LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y|SPLITTER_TRACKING|SPLITTER_REVERSED)
    group1 = FXVerticalFrame.new(@splitter1, :opts => FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y)

    @splitter2 = FXSplitter.new(@splitter1, :opts => LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y|SPLITTER_TRACKING|SPLITTER_REVERSED, :width => 750)
    group2 = FXHorizontalFrame.new(@splitter2, :opts => FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @gameArea = FXVerticalFrame.new(@splitter2, :opts => FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y)

    add_tree_area(group1)
    add_text_area(group2)
    add_game_area(@gameArea)
  end

  def add_tree_area(group)
  	@dirTree = FXTreeList.new(group, :opts => (LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|TREELIST_SHOWS_LINES|TREELIST_SHOWS_BOXES|TREELIST_ROOT_BOXES))
  	@dirTree.connect(SEL_DOUBLECLICKED, method(:treeSelection))
  end

  def add_text_area(group)
    #textScrollArea = FXScrollArea.new(group, :opts => (LAYOUT_FILL_X|LAYOUT_FILL_Y|VSCROLLER_ALWAYS))
    @numberTxt = FXText.new(group, :opts => TEXT_READONLY|LAYOUT_FILL_Y|VSCROLLER_NEVER)

  	@mainTxt = FXText.new(group, :opts => TEXT_WORDWRAP|TEXT_SHOWACTIVE|TEXT_AUTOSCROLL|LAYOUT_FILL|VSCROLLER_NEVER)
		@mainTxt.text = ""
    @mainTxt.connect(SEL_CHANGED, method(:updateLineNumbers))
  end

  def add_game_area(group)
    #User Profile
    FXLabel.new(group, @currentUser["user_name"], nil, :opts => JUSTIFY_LEFT|LAYOUT_FILL_ROW).setFont(FXFont.new(getApp(), "helvetica", 24, FONTWEIGHT_BOLD,FONTSLANT_ITALIC, FONTENCODING_DEFAULT))

    if(@currentUser["user_character"] != nil)
      logo = FXPNGImage.new(getApp(), File.open(@currentCharacterPicturePath + "/" + @currentUser["user_character"] + ".png", "rb").read, :opts => IMAGE_KEEP)
      logo.scale(174, 174)
      @image = FXImageFrame.new(group, @logo, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
      @image.image = logo
    else
      @image = FXImageFrame.new(group, @logo, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
    end

    #Experience
    FXLabel.new(group, "Experience", nil, :opts => JUSTIFY_LEFT|LAYOUT_FILL_ROW).setFont(FXFont.new(getApp(), "helvetica", 16, FONTWEIGHT_BOLD,FONTSLANT_ITALIC, FONTENCODING_DEFAULT))
    #experienceTarget = FXDataTarget.new(@currentUser["user_experience"])
    FXProgressBar.new(group, @userExperienceDataTarget, FXDataTarget::ID_VALUE, (LAYOUT_FILL_X|FRAME_SUNKEN|FRAME_THICK|PROGRESSBAR_PERCENTAGE|LAYOUT_FILL_COLUMN|LAYOUT_FILL_ROW))

    #Currency
    horframe = FXHorizontalFrame.new(group, LAYOUT_SIDE_TOP | LAYOUT_FILL_X)
    FXLabel.new(horframe, "Currency", nil, JUSTIFY_LEFT|LAYOUT_FILL_ROW).setFont(FXFont.new(getApp(), "helvetica", 12, FONTWEIGHT_BOLD,FONTSLANT_ITALIC, FONTENCODING_DEFAULT))
    currencyField = FXTextField.new(horframe, 0, @userCurrencyDataTarget, FXDataTarget::ID_VALUE, :opts => TEXTFIELD_READONLY|LAYOUT_FILL_X)

    # Ability Points
    horframe = FXHorizontalFrame.new(group, LAYOUT_SIDE_TOP | LAYOUT_FILL_X)
    FXLabel.new(horframe, "Ability Points", nil, JUSTIFY_LEFT|LAYOUT_FILL_ROW).setFont(FXFont.new(getApp(), "helvetica", 12, FONTWEIGHT_BOLD,FONTSLANT_ITALIC, FONTENCODING_DEFAULT))
    FXTextField.new(horframe, 0, @userAbilityPointsDataTarget, FXDataTarget::ID_VALUE, :opts => TEXTFIELD_READONLY|LAYOUT_FILL_X)

    #Last Badge Earned
    FXButton.new(group, "Last Badge Earned", nil, getApp(), :opts =>FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT, :padLeft => 10, :padRight => 10, :padTop => 5, :padBottom => 5)

    #Avatar Customisation
    FXButton.new(group, "Avatar Customisation", nil, getApp(), :opts =>FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT, :padLeft => 10, :padRight => 10, :padTop => 5, :padBottom => 5)

    #Avatar Shop
    shopButton = FXButton.new(group, "Avatar Store", nil, getApp(), :opts =>FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT, :padLeft => 10, :padRight => 10, :padTop => 5, :padBottom => 5)
    shopButton.connect(SEL_COMMAND) do |sender, selector, ptr|
      store = AvatarStore.new(self, @currentUser, @characterIcons, @currentCharacterPicturePath, @guiIcons, @currentItemsPath)
      if store.execute != 0
        puts "store closed"
      end
    end
  end

  def newDirectory(currentDirectory, currentLevel)
  	fileName = currentDirectory.basename.to_s

  	@directoryHash[fileName] = currentDirectory.expand_path
  	@directoryTree = Tree::TreeNode.new(currentDirectory.expand_path, fileName)
  	newLevel = @dirTree.appendItem(currentLevel, fileName, @guiIcons["icon_folder_open"], @guiIcons["icon_folder_closed"])

  	currentDirectory.each_child{|childDirectory|
  		childFileName = childDirectory.basename.to_s

  		@directoryHash[childFileName] = childDirectory.expand_path
  		@directoryTree << Tree::TreeNode.new(childDirectory.expand_path, childFileName)

  		if(childDirectory.directory?())
  			newDirectory(childDirectory, newLevel)
  		else
  			@dirTree.appendItem(newLevel, childFileName, @guiIcons["icon_doc"], @guiIcons["icon_doc"])
  		end

  	}
  end

  def treeSelection(sender, selector, data)
  	load_file(data.to_s)
	end

  def updateLineNumbers(sender, selector, data)
    addLineNumbers()
  end

  def addLineNumbers()
    if(@totalLines != @mainTxt.text.lines.count)
      @totalLines = @mainTxt.text.lines.count
      @numberTxt.text = ""
      @totalLines.times do |i|
        @numberTxt.text = @numberTxt.text + i.to_s + "\n"
      end
    end
  end

  def createCharacterIcons()
    @characterIcons["cando"] = makeIcon(@currentCharacterPicturePath + "/cando.png")
    @characterIcons["digard"] = makeIcon(@currentCharacterPicturePath + "/digard.png")
    # @characterIcons["successstuffed"] = nil
    # @characterIcons["fortunemate"] = nil
    # @characterIcons["chinpup"] = nil
    # @characterIcons["nevergivecup"] = nil
    # @characterIcons["motivistmas"] = nil
    # @characterIcons["prize"] = nil
  end

  def on_close()
    if @users.length != 0
      users_directory = @currentUsersPath
      Dir.mkdir(users_directory) unless File.exists?(users_directory)
      File.open(users_directory + '/userInfo.yml', 'w+') {|f| f.write(YAML.dump(@users)) }
    end
    getApp().exit(0)
  end
end

#Run code if not being used as a requirement
if __FILE__ == $0
	app = FXApp.new
  #GUIWindow.new(app, window text, width, height, iconPath, userPath, characterPicturePath, itemsPath)
	GUIWindow.new(app, "GUI", 1500, 750, @iconsPath, @usersPath, @characterPicturePath, @itemsPath)
	app.create
	app.run
end
