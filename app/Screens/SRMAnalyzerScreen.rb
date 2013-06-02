class SRMAnalyzerScreen < PM::Screen

  title "SRM Analyzer"

  attr_accessor :live_preview, :still_image_output, :captured_image_preview

  def will_appear
    @view_loaded ||= begin

      # UIView Setup
      view.setBackgroundColor UIColor.whiteColor
      set_nav_bar_left_button "Done", action: :close_modal, type: UIBarButtonItemStyleDone

      video_ratio = 1.333333333333
      self.live_preview = add UIView.new, {
        left: 0,
        top: 0,
        width: self.view.size.width,
        height: self.view.size.width * video_ratio,
        background_color: UIColor.whiteColor
      }
      self.still_image_output = AVCaptureStillImageOutput.new

      # Camera View Setup
      @session = AVCaptureSession.alloc.init
      @session.sessionPreset = AVCaptureSessionPresetLow

      captureVideoPreviewLayer = set_attributes AVCaptureVideoPreviewLayer.alloc.initWithSession(@session), {
        frame: self.live_preview.frame,
        background_color: UIColor.blueColor
      }

      self.live_preview.layer.addSublayer(captureVideoPreviewLayer)

      device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)

      error_ptr = Pointer.new(:object)
      input = AVCaptureDeviceInput.deviceInputWithDevice(device, error:error_ptr)
      error = error_ptr #De-reference the pointer.
      if !input
        # Handle the error appropriately.
        NSLog("ERROR: trying to open camera: %@", error)
      else
        @session.addInput(input)
        self.still_image_output.setOutputSettings({AVVideoCodecKey: AVVideoCodecJPEG})

        @session.addOutput(still_image_output)
        @session.startRunning
      end

      #Create the gradient view.
      gradient_view_size = self.live_preview.frame.size.width / 3
      @gradient_view = add UIView.new, {
        left: view.frame.size.width-gradient_view_size,
        top: 0,
        width: gradient_view_size,
        height: self.view.frame.size.height - gradient_view_size,
        background_color: UIColor.whiteColor,
        # Shadow
        shadowColor: UIColor.blackColor.CGColor,
        shadowOpacity: 0.8,
        shadowRadius: 3.0,
        shadowOffset: CGSizeMake(2.0, 2.0)
      }

      @gradient = CAGradientLayer.layer
      @gradient.frame = view.bounds
      @gradient.colors = SRM.spectrum

      @gradient_view.layer.insertSublayer(@gradient, atIndex:0)

      # Placeholder for captured image.
      self.captured_image_preview = add UIImageView.new, {
        left: self.view.frame.size.width - gradient_view_size,
        top: self.view.frame.size.height - gradient_view_size,
        width: gradient_view_size,
        height: gradient_view_size,
        content_mode: UIViewContentModeScaleAspectFit
      }
      self.captured_image_preview.setBackgroundColor UIColor.orangeColor

      # Placeholder for average image color.
      @average_color = add UIView.new, {
        left: 0,
        top: self.view.frame.size.height - gradient_view_size,
        width: self.view.frame.size.width - gradient_view_size,
        height: gradient_view_size,
        background_color: UIColor.whiteColor
      }

      # Add the target image over top of the live camera view.
      target_image = UIImage.imageNamed("srm_analyzer_target.png")
      @target_area = add UIImageView.alloc.initWithImage(target_image), {
        left: (self.live_preview.frame.size.width / 3) - (target_image.size.width/2),
        top: (self.live_preview.frame.size.height / 2) - (target_image.size.height/2),
        width: target_image.size.width,
        height: target_image.size.height
      }

      # Create the red Slider bar on the the gradient view.
      @slider = add UIView.new, {
        left: @gradient_view.frame.origin.x,
        top: @gradient_view.frame.origin.y,
        width: @gradient_view.frame.size.width,
        height: 2,
        background_color: UIColor.redColor
      }
      @slider_constraints = {
        origin: @gradient_view.frame.origin.y,
        height: @gradient_view.frame.size.height
      }

      # Create the button
      capture_image = UIImage.imageNamed("CaptureButton.png")
      capture_image_pressed = UIImage.imageNamed("CaptureButton.png")
      @capture_button = add UIButton.buttonWithType(UIButtonTypeCustom), {
        left: (self.captured_image_preview.frame.size.width / 2) - (capture_image.size.width / 2) + self.captured_image_preview.frame.origin.x,
        top: (self.captured_image_preview.frame.size.height / 2) - (capture_image.size.height / 2) + self.captured_image_preview.frame.origin.y,
        width: capture_image.size.width,
        height: capture_image.size.height
      }
      @capture_button.setBackgroundImage(capture_image, forState: UIControlStateNormal)
      @capture_button.setBackgroundImage(capture_image_pressed, forState: UIControlStateHighlighted)

      @capture_button.when(UIControlEventTouchUpInside) do
        captureNow
      end

      # @camera_timer = EM.add_periodic_timer 1.0 do
      #   captureNow
      # end

      @color_view_label = add UILabel.new, {
        frame: @average_color.frame,
        text: "Calculated SRM: --",
        font: UIFont.boldSystemFontOfSize(UIFont.systemFontSize),
        textAlignment: UITextAlignmentCenter,
        background_color: UIColor.clearColor
      }

    end
  end

  def will_disappear
    if !@session.nil? && @session.respond_to?("running") && @session.running == true
      @session.stopRunning
    end
  end

  def captureNow
    videoConnection = nil
    still_image_output.connections.each do |connection|
      connection.inputPorts.each do |port|
        if port.mediaType == AVMediaTypeVideo
          videoConnection = connection
          break
        end
      end
      break if videoConnection
    end

    NSLog("about to request a capture from: %@", still_image_output)
    still_image_output.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler:lambda do |imageSampleBuffer, error|
      # exifAttachments = CMGetAttachment( imageSampleBuffer, KCGImagePropertyExifDictionary, nil)
      # if exifAttachments
      #   # Do something with the attachments.
      #   NSLog("attachements: %@", exifAttachments)
      # else
      #   NSLog("no attachments")
      # end

      imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer)
      image = UIImage.alloc.initWithData(imageData)

      ap "Got new image: #{image}"

      cropped = image
                  .image_resized(self.live_preview.frame.size)
                  .crop(@target_area.frame)
      self.captured_image_preview.image = cropped

      avg_color = cropped.averageColorAtPixel(CGPointMake(cropped.size.width, cropped.size.height), radius:(cropped.size.width / 2.0))
      @average_color.setBackgroundColor avg_color

      my_calculated_srm = SRM.closest_srm_to_color(avg_color)
      move_slider_to_srm(my_calculated_srm[0].to_i)

      if my_calculated_srm[0].to_i > SRM.steps.count / 2
        text_color = UIColor.whiteColor
      else
        text_color = UIColor.blackColor
      end

      if my_calculated_srm[1] < 50
        set_attributes @color_view_label, {
          number_of_lines: 1,
          text: "Calculated SRM: #{my_calculated_srm[0]}",
          textColor: text_color
        }
      else
        # Warn them that a good match could not be found
        set_attributes @color_view_label, {
          number_of_lines: 2,
          text: "Calculated SRM: #{my_calculated_srm[0]}\n(Not a good match)",
          textColor: text_color
        }
      end
     end)
  end

  def scanButtonPressed
    @scanningLabel.setHidden(false)
    self.performSelector("hideLabel:", withObject:@scanningLabel, afterDelay:2)
  end

  def hideLabel(label)
    label.setHidden(true)
  end

  def should_rotate(orientation)
    puts "Trying to determine rotation"
    UIDeviceOrientationPortrait == orientation
  end

  def should_autorotate
    puts "should autorotate?"
    false
  end

  def supported_orientations
    puts "checking supported orientations"
    orientations = 0
    orientations |= UIInterfaceOrientationMaskPortrait
    orientations
  end

  def move_slider_to_srm(srm)
    UIView.animateWithDuration(0.75,
      animations:lambda {
        @slider.frame = CGRectMake(
          @slider.frame.origin.x,
          @slider_constraints[:origin] + (@slider_constraints[:height] / (SRM.steps.count + 1) * srm),
          @slider.frame.size.width,
          @slider.frame.size.height
        )
      })
  end

  def close_modal
    # EM.cancel_timer(@camera_timer)
    close
  end

end
