class StylesScreen < ProMotion::SectionedTableScreen
  title "Back"
  searchable :placeholder => "Search Styles"

  def will_appear
    self.setTitle("orginization"._, subtitle:"version"._)

    set_attributes self.view, {
      backgroundColor: UIColor.whiteColor
    }

    set_nav_bar_right_button UIImage.imageNamed("info.png"), action: :open_info_screen
  end

  # def on_appear
  #   @opened_screen ||= begin
  #     open_srm_analyzer_screen
  #   end
  # end

  def table_data
  	@table_setup ||= begin
      s = []

      s << introduction_section
      s << judging_tools_section

      sections.each do |section|
    		s << {
    			title: section.format_title,
    			cells: build_cells(section)
    		}
    	end

      s
    end
  end

  def build_cells(path)
      c = []
    	section_listing(path).each do |style|
        c << {
    			title: style.format_title,
          cell_identifier: "StyleCell",
    			action: :open_style,
    			arguments: {:path => File.join(guidelines_path, path, style), :name => style.format_title}
    		}
    	end
  	 c
  end

  def table_data_index
    table_data.collect do |section|
      first = section[:title].split(" ").first
      if ("A".."Z").to_a.include? first[0].upcase
        first[0]
      else
        first.to_i.to_s
      end
    end
  end

  def judging_tools_section
    tools = {
      title: "Judging Tools",
      cells:
      [{
        title: "Flavor Wheel",
        cell_identifier: "ImagedCell",
        image: "flavor_wheel_thumb.png",
        action: :open_flavor_wheel,
        searchable: false
      },{
        title: "SRM Spectrum",
        cell_identifier: "ImagedCell",
        image: "srm_spectrum_thumb.png",
        action: :open_srm_screen,
        search_text: "color"
      },{
        title: "SRM Analyzer",
        cell_identifier: "ImagedCell",
        image: analyzer_image,
        action: :open_srm_analyzer_screen,
        search_text: "color"
      }]
    }

    tools[:cells] << torch_cell if torch_supported?
    tools
  end

  def analyzer_unlocked?
    true
  end

  def analyzer_image
    analyzer_unlocked? ? "eyedropper.png" : "lock.png"
  end

  def torch_supported?
    return true if Device.simulator? # We want the functionality in the simulator

    capture_device = Module.const_get("AVCaptureDevice")
    return false if capture_device.nil?

    AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo).hasTorch
  end

  def torch_cell
    {
      title: "Torch",
      cell_identifier: "ImagedCell",
      image: "torch.png",
      accessory: {
        view: :switch,
        action: :torch_switched,
        value: false
      },
      search_text: "light flashlight torch"
    }
  end

  def torch_switched(switch)
    toggle_torch(switch[:value]) if torch_supported?
  end

  # def toggle_torch
  #   device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)

  #   if device.torchMode == AVCaptureTorchModeOff
  #     # Create an AV session
  #     session = AVCaptureSession.new

  #     # Create device input and add to current session
  #     input = AVCaptureDeviceInput.deviceInputWithDevice(device, error:nil)
  #     session.addInput(input)

  #     # Create video output and add to current session
  #     output = AVCaptureVideoDataOutput.new
  #     session.addOutput(output)

  #     # Start session configuration
  #     session.beginConfiguration
  #     device.lockForConfiguration(nil)

  #     # Set torch to on
  #     device.setTorchMode(AVCaptureTorchModeOn)

  #     device.unlockForConfiguration
  #     session.commitConfiguration

  #     # Start the session
  #     session.startRunning

  #     # Keep the session around
  #     self.setAVSession(session)
  #   else
  #     AVSession.stopRunning
  #     AVSession = nil
  #   end

  # end

  def toggle_torch(on_off)

    return if Device.simulator?

    # check if flashlight available
    captureDeviceClass = Module.const_get("AVCaptureDevice")
    return false if captureDeviceClass.nil?

    device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    if device.hasTorch && device.hasFlash
      device.lockForConfiguration(nil)
      if on_off
        device.setTorchMode(AVCaptureTorchModeOn)
        device.setFlashMode(AVCaptureFlashModeOn)
      else
        device.setTorchMode(AVCaptureTorchModeOff)
        device.setFlashMode(AVCaptureFlashModeOff)
      end
      device.unlockForConfiguration
    end
  end

  def introduction_section
    all_introductions = introductions_listing
    intro = {
      title: "Introduction",
      cells: []
    }
    intro[:title] << "s" if all_introductions.count > 1

    all_introductions.each do |d|
      title = File.basename(d, File.extname(d))
      intro[:cells] <<
      {
        title: title,
        cell_identifier: "ImagedCell",
        image: { image: UIImage.imageNamed("logo_thumb.png") },
        action: :open_style,
        arguments: {
          :path => File.join(guidelines_path, d),
          :name => title
        }
      }
    end

    intro
  end

  def open_style(args={})
  	open DetailScreen.new(args)
  end

  def open_info_screen(args={})
    open DetailScreen.new(
      :path => File.join(guidelines_path, "Info.html"),
      :name => "About"
    )
  end

  def open_flavor_wheel(args={})
    open FlavorWheelScreen.new
  end

  def open_srm_screen(args={})
    open SRMScreen.new
  end

  def open_srm_analyzer_screen(args={})
    if analyzer_unlocked?
      open SRMAnalyzerScreen.new, {modal:true, nav_bar:true}
    else
      open SRMAnalyzerDemoScreen.new
    end
  end

  def sections
  	# Returns all folder names
    Dir.entries(guidelines_path).select{|d|
      File.directory?(File.join(guidelines_path, d)) and not_dotfile(d)
  	}
  end

  def guidelines_path
  	File.join(App.resources_path, "guidelines")
	end

	def section_listing(category)
		path = File.join(guidelines_path, category)
    Dir.entries(path).select{|d|
  		!File.directory?(File.join(path, d)) and not_dotfile(d)
  	}
	end

  def introductions_listing
    Dir.entries(guidelines_path).select{|d|
      d.include? "Introduction"
    }
  end

  def not_dotfile(d)
    !(d =='.' || d == '..' || d[0] == '.')
  end

end
