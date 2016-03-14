require 'fox16'
require 'tree'
require 'pathname'
include Fox

class GUITestWindow < FXMainWindow
	def initialize(app, title, width, height)
		super(app, title, :opts => DECOR_ALL, :width => width, :height => height)

		@icon_folder_open   = makeIcon("icons/minifolderopen.png")
    @icon_folder_closed = makeIcon("icons/minifolder.png")
    @icon_doc           = makeIcon("icons/minidoc.png")

    @characterIcons = Hash.new
    createCharacterIcons()

    @directoryHash = Hash.new
    @directoryTree
		add_menu_bar
		add_status_bar
		add_splitter_area

		
	end

	def create
		super
		show(PLACEMENT_SCREEN)
	end

	private
	def add_menu_bar

		#Create new menu bar
		menu_bar = FXMenuBar.new(self, LAYOUT_SIDE_TOP | LAYOUT_FILL_X)  

		#Create new file menu
    file_menu = FXMenuPane.new(self)  
    FXMenuTitle.new(menu_bar, "File", :popupMenu => file_menu)

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
      dialog.patternList = ["All Files (*)"]  
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
      dialog = FXFileDialog.getSaveFilename(self, "Save a File", "")
      save_file(dialog)  
    end  

    #Exit Command
    FXMenuSeparator.new(file_menu)  

    exit_cmd = FXMenuCommand.new(file_menu, "Exit")  
    exit_cmd.connect(SEL_COMMAND) do  
      exit  
    end  
	end

	def load_file(filename)  
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
  	@splitter = FXSplitter.new(self, (LAYOUT_SIDE_TOP|LAYOUT_FILL_X|LAYOUT_FILL_Y|SPLITTER_TRACKING|SPLITTER_REVERSED))
    group1 = FXVerticalFrame.new(@splitter,FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y, :width => 100)
    group2 = FXHorizontalFrame.new(@splitter,FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y, :width => 750)
    group3 = FXVerticalFrame.new(@splitter,FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y, :width => 174)

    add_tree_area(group1)
    add_text_area(group2)
    add_game_area(group3)
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
    FXLabel.new(group, "Profile", nil, :opts => JUSTIFY_LEFT|LAYOUT_FILL_ROW).setFont(FXFont.new(getApp(), "helvetica", 24, FONTWEIGHT_BOLD,FONTSLANT_ITALIC, FONTENCODING_DEFAULT))
    @logo = FXPNGImage.new(getApp(), File.open("characterPictures/cando.png", "rb").read, :opts => IMAGE_KEEP)
    image = FXImageFrame.new(group, @logo, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
    @logo.scale(174, 174)

    #Experience
    FXLabel.new(group, "Experience", nil, :opts => JUSTIFY_LEFT|LAYOUT_FILL_ROW).setFont(FXFont.new(getApp(), "helvetica", 16, FONTWEIGHT_BOLD,FONTSLANT_ITALIC, FONTENCODING_DEFAULT))
    @experienceTarget = FXDataTarget.new(50)
    FXProgressBar.new(group, @experienceTarget, FXDataTarget::ID_VALUE, (LAYOUT_FILL_X|FRAME_SUNKEN|FRAME_THICK|PROGRESSBAR_PERCENTAGE|LAYOUT_FILL_COLUMN|LAYOUT_FILL_ROW))

    #Currency
    horframe = FXHorizontalFrame.new(group, LAYOUT_SIDE_TOP | LAYOUT_FILL_X)
    FXLabel.new(horframe, "Currency", nil, JUSTIFY_LEFT|LAYOUT_FILL_ROW).setFont(FXFont.new(getApp(), "helvetica", 12, FONTWEIGHT_BOLD,FONTSLANT_ITALIC, FONTENCODING_DEFAULT))
    FXTextField.new(horframe, 0, @experienceTarget, FXDataTarget::ID_VALUE, FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X)

    # Ability Points
    horframe = FXHorizontalFrame.new(group, LAYOUT_SIDE_TOP | LAYOUT_FILL_X)
    FXLabel.new(horframe, "Ability Points", nil, JUSTIFY_LEFT|LAYOUT_FILL_ROW).setFont(FXFont.new(getApp(), "helvetica", 12, FONTWEIGHT_BOLD,FONTSLANT_ITALIC, FONTENCODING_DEFAULT))
    FXTextField.new(horframe, 0, @experienceTarget, FXDataTarget::ID_VALUE, FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X)

    #Last Badge Earned
    FXButton.new(group, "Last Badge Earned", nil, getApp(), :opts =>FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT, :padLeft => 10, :padRight => 10, :padTop => 5, :padBottom => 5)

    #Avatar Customisation
    FXButton.new(group, "Avatar Customisation", nil, getApp(), :opts =>FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT, :padLeft => 10, :padRight => 10, :padTop => 5, :padBottom => 5)

    #Avatar Shop
    FXButton.new(group, "Avatar Store", nil, getApp(), :opts =>FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT, :padLeft => 10, :padRight => 10, :padTop => 5, :padBottom => 5)

  end

  def newDirectory(currentDirectory, currentLevel)
  	fileName = currentDirectory.basename.to_s

  	@directoryHash[fileName] = currentDirectory.expand_path
  	@directoryTree = Tree::TreeNode.new(currentDirectory.expand_path, fileName)
  	newLevel = @dirTree.appendItem(currentLevel, fileName, @icon_folder_open, @icon_folder_closed)

  	currentDirectory.each_child{|childDirectory|
  		childFileName = childDirectory.basename.to_s

  		@directoryHash[childFileName] = childDirectory.expand_path
  		@directoryTree << Tree::TreeNode.new(childDirectory.expand_path, childFileName)

  		if(childDirectory.directory?())
  			newDirectory(childDirectory, newLevel)
  		else
  			@dirTree.appendItem(newLevel, childFileName, @icon_doc, @icon_doc)
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
    @characterIcons["cando"] = makeIcon("characterPictures/cando.png")
  end
end

#Run code if not being used as a requirement
if __FILE__ == $0
	app = FXApp.new
	GUITestWindow.new(app, "GUI Test", 1024, 600)
	app.create
	app.run
end