module Zajal
  # This module contains methods that draw basic geometric primitives.
  # Methods either draw directly to the screen (e.g. {#circle},
  # {#square}) or affect subsequent drawing (e.g. {#translate}).
  # 
  # {Zajal::Graphics} mostly a wrapper for ofGraphics in openFrameworks.
  # 
  # @see http://www.openframeworks.cc/documentation/graphics/ofGraphics.html
  # 
  # @api zajal
  module Graphics
    # Draw a circle
    # 
    # @overload circle x, y, radius
    #   @param [Numeric] x x coordinate of circle's center
    #   @param [Numeric] y y coordinate of circle's center
    #   @param [Numeric] radius radius of the circle
    #   @demo Single circle
    #     circle 50, 50, 25
    #   @demo Four circles
    #     circle 25, 25, 20
    #     circle 75, 25, 20
    #     circle 75, 75, 20
    #     circle 25, 75, 20
    # 
    # @overload circle x, y, z, radius
    #   @param [Numeric] x x coordinate of circle's center
    #   @param [Numeric] y y coordinate of circle's center
    #   @param [Numeric] z z coordinate of circle's center
    #   @param [Numeric] radius radius of the circle
    # 
    # @overload circle point, radius
    #   `point` can be any object that responds to `x` and `y` messages
    #   @param [#x,#y] point the circle's center
    #   @param [Numeric] radius radius of the circle
    #   @demo Point object
    #     class MyPoint
    #       def initialize x, y
    #         @x = x
    #         @y = y
    #       end
    # 
    #       def x
    #         @x
    #       end
    # 
    #       def y
    #         @y
    #       end
    #     end
    #     
    #     p = MyPoint.new 25, 75
    #     circle p, 20
    # 
    #   @demo Using OpenStruct
    #     p = OpenStruct.new
    #     p.x = 80
    #     p.y = 20
    #   
    #     circle p, 10
    # 
    # @see #circle_resolution
    def circle *args
      x = y = z = r = 0

      case args
      when Signature[[:x, :y], :to_f]
        x, y = args.first.x, args.first.y
        r = args.last

      when Signature[[:x, :y, :z], :to_f]
        x, y, z = args.first.x, args.first.y, args.first.z
        r = args.last

      when Signature[:to_f, :to_f, :to_f]
        x, y, r = *args

      when Signature[:to_f, :to_f, :to_f, :to_f]
        x, y, z, r = *args
      end

      Native.ofCircle x.to_f, y.to_f, z.to_f, r.to_f
    end

    # @overload alpha_blending on
    #   Enable or disable alpha blending
    #   
    #   Alpha blending allows for transparent colors in colors and images, but can
    #   slow down your sketch. You can enable and disable it as needed.
    # 
    #   @param on [Boolean] true to enable alpha blending, false to disable
    #   @demo With and without blending
    #     alpha_blending false
    #     color :white, 128
    #     circle 40, 25, 20
    #     circle 60, 25, 20
    #     
    #     alpha_blending true
    #     color :white, 128
    #     circle 40, 75, 20
    #     circle 60, 75, 20
    # 
    # @overload alpha_blending
    #   @return [Boolean] current alpha blending
    def alpha_blending on=nil
      @alpha_blending ||= false

      if on.present?
        @alpha_blending = on.to_bool
        @alpha_blending ? Native.ofEnableAlphaBlending : Native.ofDisableAlphaBlending
      end
      
      @alpha_blending
    end

    # Set the background color and clear the screen to that color 
    # 
    # @overload background red, green, blue
    #   @param [0..255] red the amount of red
    #   @param [0..255] green the amount of green
    #   @param [0..255] blue the amount of blue
    # 
    # @overload background red, green, blue, alpha
    #   @param [0..255] red the amount of red
    #   @param [0..255] green the amount of green
    #   @param [0..255] blue the amount of blue
    #   @param [0..255] alpha the amount of alpha
    # 
    # @overload background name
    #   Use a named color
    #   @param [Symbol] name the name of the color to use
    #   @demo Blue background
    #     background :blue
    #     circle 50, 50, 30
    # 
    # @overload background name, alpha
    # 
    # @overload background hue, saturation, value
    # 
    # @overload background hue, saturation, value, alpha
    # 
    # @overload background
    #   @return [Color] current background color
    # 
    # 
    # @return [nil] Nothing
    def background *args
      unless args.empty?
        @background = Color.new(color_mode, *args)
        r, g, b, a = @background.to_rgb.to_a
        Native.ofClear r.to_f, g.to_f, b.to_f, a.to_f
      end

      @background
    end

    # Draw a rectangle
    # 
    # @overload rectangle x, y, width, height
    #   @demo Single thin rectangle
    #     rectangle 45, 10, 10, 80
    #   
    #   @demo Single wide rectangle
    #     rectangle 25, 10, 50, 80
    #   
    #   @demo Carefully placed rectangles
    #     rectangle 10, 10, 1, 80
    #     rectangle 12, 10, 2, 80
    #     rectangle 15, 10, 3, 80
    #     rectangle 19, 10, 4, 80
    #     rectangle 24, 10, 5, 80
    #     rectangle 30, 10, 6, 80
    #     rectangle 37, 10, 7, 80
    #     rectangle 45, 10, 8, 80
    #     rectangle 54, 10, 9, 80
    #     rectangle 64, 10, 10, 80
    #     rectangle 75, 10, 11, 80
    #   @param x [Numeric] x coordinate of top left corner
    #   @param y [Numeric] y coordinate of top left corner
    #   @param width [Numeric] width of rectangle
    #   @param height [Numeric] height of rectangle
    # 
    # @overload rectangle x, y, z, width, height
    # @overload rectangle x, y, z, width, height
    # @overload rectangle x, y, size_object
    # @overload rectangle x, y, size_object
    # 
    # @see #square
    def rectangle *args
      x, y, z, w, h = 0

      case args
      when Signature[[:x,:y], [:width,:height]]
        corner, dim = *args
        x, y = corner.x, corner.y
        z = corner.z if corner.respond_to? :z
        w, h = dim.width, dim.height

      when Signature[[:x,:y], :to_f, :to_f]
        corner, w, h = *args
        x, y = corner.x, corner.y
        z = corner.z if corner.respond_to? :z

      when Signature[:to_f, :to_f, [:width, :height]]
        x, y, dim = *args
        w, h = dim.width, dim.height

      when Signature[:to_f, :to_f, :to_f, :to_f]
        x, y, w, h = *args

      when Signature[:to_f, :to_f, :to_f, :to_f, :to_f]
        x, y, z, w, h = *args
      end

      Native.ofRect x.to_f, y.to_f, z.to_f, w.to_f, h.to_f
    end

    # Draw a line between two points
    # 
    # @overload line x1, y1, x2, y2
    #   @demo Single line
    #     line 10, 10, 90, 90
    #   
    #   @demo Multiple lines
    #     line 10, 0, 90, 80
    #     line 10, 10, 90, 90
    #     line 10, 20, 90, 100
    #   
    #   @demo Mesh
    #     10.times do |i|
    #       line i*10, 100, 100, 100-i*10
    #     end
    #   
    #   @param x1 [Numeric] the x coordinate of the first point 
    #   @param y1 [Numeric] the y coordinate of the first point 
    #   @param x2 [Numeric] the x coordinate of the second point 
    #   @param y2 [Numeric] the y coordinate of the second point 
    # 
    # @overload line x1, y1, z1, x2, y2, z2
    #   @param x1 [Numeric] the x coordinate of the first point 
    #   @param y1 [Numeric] the y coordinate of the first point 
    #   @param z1 [Numeric] the z coordinate of the first point 
    #   @param x2 [Numeric] the x coordinate of the second point 
    #   @param y2 [Numeric] the y coordinate of the second point 
    #   @param z2 [Numeric] the z coordinate of the second point 
    # 
    # @overload line start_point, end_point
    #   @demo Point objects
    #     a = OpenStruct.new
    #     b = OpenStruct.new
    #   
    #     a.x = 10
    #     a.y = 20
    #     b.x = 90
    #     b.y = 70
    #   
    #     line a, b
    # 
    def line *args
      x1 = y1 = z1 = x2 = y2 = z2 = 0

      case args
      when Signature[[:x,:y] ,[:x,:y]]
        x1, y1 = args.first.x, args.first.y
        x2, y2 = args.last.x, args.last.y

      when Signature[[:x,:y,:z] ,[:x,:y,:z]]
        x1, y1, z1 = args.first.x, args.first.y, args.first.z
        x2, y2, z2 = args.last.x, args.last.y, args.last.z

      when Signature[:to_f ,:to_f ,:to_f ,:to_f]
        x1, y1, x2, y2 = *args

      when Signature[:to_f ,:to_f ,:to_f ,:to_f ,:to_f ,:to_f]
        x1, y1, z1, x2, y2, z2 = *args
      end

      Native.ofLine x1.to_f, y1.to_f, z1.to_f, x2.to_f, y2.to_f, z2.to_f
    end

    # @overload line_width new_width
    #   Set the width of subsequent lines
    #   @demo Two lines
    #     line_width 1
    #     line 10, 5, 90, 85
    #   
    #     line_width 5
    #     line 10, 15, 90, 95
    # 
    #   @param new_width [Numeric] the width of the lines
    # 
    # @overload line_width
    #   Get the current line width
    #   @demo
    #     text line_width
    #     line_width 10
    #     text line_width
    #   @return [Numeric] current line width
    # 
    # 
    def line_width new_width=nil
      @line_width ||= 1

      if new_width.present?
        @line_width = new_width.to_f
        Native.ofSetLineWidth @line_width
      else
        @line_width
      end
    end

    # Draw a square
    # 
    # @overload square x, y, size
    #   Draw a square centered at `x`,`y` with size `size`.
    #   @demo Single square
    #     square 10, 10, 80
    #   
    #   @demo Corner to corner
    #     square 10, 10, 10
    #     square 20, 20, 20
    #     square 40, 40, 40
    #   
    #   @demo Carefully placed squares
    #     square 10, 50, 1
    #     square 12, 50, 2
    #     square 15, 50, 3
    #     square 19, 50, 4
    #     square 24, 50, 5
    #     square 30, 50, 6
    #     square 37, 50, 7
    #     square 45, 50, 8
    #     square 54, 50, 9
    #     square 64, 50, 10
    #     square 75, 50, 11
    #   
    #   @param x [Numeric] x coordinate of the top left corner
    #   @param y [Numeric] y coordinate of the top left corner
    #   @param size [Numeric] the width and height of the square
    #   
    #   @return [nil] Nothing
    def square *args
      x = y = z = s = 0

      case args
      when Signature[[:x,:y,:z], :to_f]
        pos, s = *args
        x, y, z = pos.x, pos.y, pos.z

      when Signature[[:x,:y], :to_f]
        pos, s = *args
        x, y = pos.x, pos.y

      when Signature[:to_f, :to_f, :to_f, :to_f]
        x, y, z, s = *args

      when Signature[:to_f, :to_f, :to_f]
        x, y, s = *args
      end

      rectangle x, y, z, s, s
    end

    # Move all subsequent drawing
    # 
    # @demo Same circle shifted
    #   circle 20, 50, 10
    #   translate 60, 0
    #   circle 20, 50, 10
    # 
    # @param x [Numeric] amount to move horizontally
    # @param y [Numeric] amount to move vertically
    # @param z [Numeric] amount to move in depth
    # 
    # @return [nil] Nothing
    def translate x, y, z=0.0
      Native.ofTranslate x.to_f, y.to_f, z.to_f
    end

    # Scale all subsequent drawing
    # 
    # Scaling is centered at the top left corner
    # 
    # @overload scale size
    #   @demo Same circle scaled
    #     fill false
    #   
    #     scale 1
    #     circle 10, 10, 10
    #   
    #     scale 1.5
    #     circle 10, 10, 10
    #   
    #     scale 2
    #     circle 10, 10, 10
    #   
    #     scale 2.5
    #     circle 10, 10, 10
    #   
    #     scale 3
    #     circle 10, 10, 10
    #   @param size [Numeric] amount to scale in all directions
    # 
    # @overload scale x, y
    #   @param x [Numeric] amount to scale in x
    #   @param y [Numeric] amount to scale in y
    # 
    # @overload scale x, y, z
    #   @param x [Numeric] amount to scale in x
    #   @param y [Numeric] amount to scale in y
    #   @param z [Numeric] amount to scale in z
    def scale x, y=nil, z=1.0
      y = x unless y.present?
      Native.ofScale x.to_f, y.to_f, z.to_f
    end

    # @overload rotate degrees
    #   Rotate all subsequent drawing
    #   
    #   Rotating is centered at the top left corner
    #   
    #   @demo Same square rotated
    #     fill false
    #     rotate 0
    #     square 50, 10, 20
    #   
    #     rotate 5
    #     square 50, 10, 20
    #   
    #     rotate 10
    #     square 50, 10, 20
    #   
    #     rotate 15
    #     square 50, 10, 20
    #   
    #     rotate 20
    #     square 50, 10, 20
    #   
    #     rotate 25
    #     square 50, 10, 20
    # @overload rotate degrees, x, y, z
    # @overload rotate degrees, vector
    def rotate *args
      degrees = x = y = z = 0

      case args
      when Signature[:to_f]
        degrees = args.first
        z = 1

      when Signature[:to_f, [:x,:y,:z]]
        degrees, v = *args
        x, y, z = v.x, v.y, v.z

      when Signature[:to_f, :to_f, :to_f, :to_f]
        degrees, x, y, z = *args
      end

      Native.ofRotate degrees.to_f, x.to_f, y.to_f, z.to_f
    end

    # Set the color that subsequent drawing will be done in
    # 
    # @overload color red, green, blue
    #   `red`, `green`, and `blue` are numbers between 0 and 255
    #   @demo RGB colors
    #     color_mode :rgb
    #     color 200, 128, 64
    #     circle 20, 50, 15
    #   
    #     color 30, 128, 200
    #     circle 80, 50, 15
    #   
    # @overload color red, green, blue, alpha
    # 
    # @overload color name
    #   
    #   @demo Common colors
    #     color :yellow
    #     circle 20, 50, 15
    #     color :lime_green
    #     circle 80, 50, 15
    # 
    #   @demo Esotetic colors
    #     color :light_goldenrod_yellow
    #     circle 20, 20, 15
    #   
    #     color :medium_aquamarine
    #     circle 80, 20, 15
    #   
    #     color :cornflower_blue
    #     circle 20, 80, 15
    #   
    #     color :light_slate_gray
    #     circle 80, 80, 15
    # 
    # @overload color name, alpha
    # @overload color gray
    # @overload color gray, alpha
    # @overload color hue, saturation, value
    #   @demo HSV colors
    #     color_mode :hsv
    #     background :white
    #   
    #     color 0, 200, 200
    #     circle 20, 50, 15
    #   
    #     color 200, 200, 200
    #     circle 80, 50, 15
    #   
    #   @demo Splatter
    #     translate width/2, height/2
    #     
    #     color_mode :hsv
    #     clear :black
    #     
    #     128.times do |i|
    #       color i*2, 255, 255
    #       line 0, 0, cos(i/128.0 * PI)*50, sin(i)*50
    #     end
    # 
    # @overload color hue, saturation, value, alpha
    # @overload color
    #   @return [Color] current color
    # 
    # @return [nil] Nothing
    def color *args
      unless args.empty?
        @color = Color.new(color_mode, *args)
        r, g, b, a = @color.to_rgb.to_a
        Native.ofSetColor r.to_i, g.to_i, b.to_i, a.to_i
      end

      @color
    end

    # @overload color_mode mode
    #   Set the way subsequent colors will be interpreted
    # 
    #   `:rgb` and `:hsv` are recognized
    #   
    #   @demo Splatter
    #     translate width/2, height/2
    #     
    #     color_mode :hsv
    #     clear :black
    #     
    #     128.times do |i|
    #       color i*2, 255, 255
    #       line 0, 0, cos(i/128.0 * PI)*50, sin(i)*50
    #     end
    #   @param mode [Symbol] new color mode
    #   
    # @overload color_mode
    #   @return [Symbol] current color mode
    def color_mode mode=nil
      @color_mode ||= :rgb

      @color_mode = mode.to_sym if mode.present?
      @color_mode
    end

    # Clear the canvas to a color
    # 
    # @overload clear red, green, blue
    #   @param red [0..255] the amount of red
    #   @param green [0..255] the amount of green
    #   @param blue [0..255] the amount of blue
    # 
    # @overload clear r, g, b, a
    #   @param red [0..255] the amount of red
    #   @param green [0..255] the amount of green
    #   @param blue [0..255] the amount of blue
    #   @param alpha [0..255] the amount of alpha
    # 
    # @overload clear hue, saturation, value
    # @overload clear hue, saturation, value, alpha
    # @overload clear name
    # @overload clear name, alpha
    # 
    # @return [nil] Nothing
    def clear *args
      r, g, b, a = Color.new(color_mode, *args).to_rgb.to_a
      Native.ofClear r.to_f, g.to_f, b.to_f, a.to_f
    end

    def push_matrix
        Native.ofPushMatrix
    end

    def pop_matrix
        Native.ofPushMatrix
    end

    def matrix
        push_matrix
        yield
        pop_matrix
    end

    # @overload rectangle_mode mode
    #   @demo Rectangle modes
    #     rectangle_mode :corner
    #     color :white
    #     square 50, 50, 20
    #   
    #     rectangle_mode :center
    #     color :black
    #     square 50, 50, 20
    # @overload rectangle_mode
    #   @return [Symbol] current rectangle mode
    def rectangle_mode mode=nil
      if mode.present?
        Native.ofSetRectMode mode
      else
        Native.ofGetRectMode
      end
    end

    # @overload circle_resolution new_resolution
    #   @demo Low resolution circle
    #     circle_resolution 10
    #     circle 50, 50, 45
    #   
    #   @demo Medium resolution circle
    #     circle_resolution 20
    #     circle 50, 50, 45
    #   
    #   @demo High resolution circle
    #     circle_resolution 60
    #     circle 50, 50, 45
    # 
    # @overload circle_resolution
    def circle_resolution new_resolution=nil
      @circle_resolution ||= 22 # TODO what is the default resolution

      if new_resolution.present?
        @circle_resolution = new_resolution.to_i
        Native.ofSetCircleResolution @circle_resolution
      else
        @circle_resolution
      end
    end

    # @overload curve_resolution new_resolution
    # @overload curve_resolution
    def curve_resolution new_resolution=nil
      @curve_resolution ||= 22 # TODO what is the default resolution

      if new_resolution.present?
        @curve_resolution = new_resolution.to_i
        Native.ofSetCurveResolution @curve_resolution
      else
        @curve_resolution
      end
    end

    # @overload sphere_resolution new_resolution
    #   @demo Low resolution sphere
    #     fill false
    #     sphere_resolution 5
    #     sphere 50, 50, 40
    #   
    #   @demo Medium resolution sphere
    #     fill false
    #     sphere_resolution 12
    #     sphere 50, 50, 40
    #   
    #   @demo High resolution sphere
    #     fill false
    #     sphere_resolution 16
    #     sphere 50, 50, 40
    # @overload sphere_resolution
    #   @return [Fixnum] current sphere resolution
    def sphere_resolution new_resolution=nil
      @sphere_resolution ||= 22 # TODO what is the default resolution

      if new_resolution.present?
        @sphere_resolution = new_resolution.to_i
        Native.ofSetSphereResolution @sphere_resolution
      else
        @sphere_resolution
      end
    end

    # @overload fill fill_or_not
    #   @demo Filled and unfilled circles
    #     fill true
    #     circle 30, 50, 15
    #   
    #     fill false
    #     circle 70, 50, 15
    # 
    # @overload fill
    #   @return [Boolean] current fill
    def fill filled=nil
      if filled.present?
        filled ? Native.ofFill : Native.ofNoFill
      else
        Native.ofGetFill == :filled
      end
    end

    # @overload blend_mode new_mode
    #   @demo Blend mode
    #     color :white, 128
    #   
    #     blend_mode :add
    #     circle 20, 25, 10
    #     circle 30, 25, 10
    #   
    #     blend_mode :subtract
    #     circle 80, 25, 10
    #     circle 70, 25, 10
    #   
    #     blend_mode :multiply
    #     circle 80, 75, 10
    #     circle 70, 75, 10
    #   
    #     blend_mode :alpha
    #     circle 20, 75, 10
    #     circle 30, 75, 10
    # 
    # @overload blend_mode
    #   @return [Symbol] current blend mode
    # 
    def blend_mode mode=nil
      @blend_mode ||= :disabled

      if mode.present?
        @blend_mode = mode
        Native.ofDisableBlendMode
        Native.ofEnableBlendMode @blend_mode unless @blend_mode == :disabled
      else
        @blend_mode
      end
    end

    # @overload point_sprites sprites
    # @overload point_sprites
    def point_sprites sprites=nil
      @point_sprites ||= false

      if sprites.present?
        @point_sprites = sprites.to_bool
        @point_sprites ? Native.ofEnablePointSprites : Native.ofDisablePointSprites
      else
        @point_sprites
      end
    end

    def push_style
      Native.ofPushStyle
    end

    def pop_style
      Native.ofPopStyle
    end

    # @demo Isolated style
    #   fill true
    #   color :white
    #   circle 30, 30, 15
    # 
    #   style do
    #     color :yellow
    #     fill false
    #     circle 70, 50, 15
    #   end
    # 
    #   circle 30, 70, 15
    def style
      push_style
      yield
      pop_style
    end

    # @overload clear_background clear
    # @overload clear_background
    def clear_background clear=nil
      if clear.present?
        Native.ofSetBackgroundAuto clear.to_bool
      else
        Native.ofbClearBg
      end
    end

    # @overload triangle x, y, size
    #   @demo Triangle
    #     triangle 50, 50, 30
    #   @demo Equilateral triangles
    #     fill false
    #     triangle 50, 50, 50
    #     triangle 50, 50, 40
    #     triangle 50, 50, 30
    #     triangle 50, 50, 20
    #     triangle 50, 50, 10
    # 
    # @overload triangle point, size
    # @overload triangle x, y, size, angle
    #   @demo Isosceles triangles
    #     fill false
    #     triangle 50, 50, 30, 170
    #     triangle 50, 50, 30, 150
    #     triangle 50, 50, 30, 130
    #     triangle 50, 50, 30, 110
    #     triangle 50, 50, 30, 90
    # 
    # @overload triangle point, size, angle
    # @overload triangle x1, y1, x2, y2, x3, y3
    #   @demo Scalene triangle
    #     fill false
    #     triangle 75, 60, 50, 50, 80, 10
    # 
    # @overload triangle point_a, point_b, point_c
    # 
    def triangle *args
      x1 = y1 = z1 = x2 = y2 = z2 = x3 = y3 = z3 = 0

      equilateral_algorithm = proc { |x, y, z, r|
        a = Math::PI - Math::PI/3
        x1 = x + cos(Math::PI/2) * r
        y1 = y - sin(Math::PI/2) * r
        z1 = z
        x2 = x + cos(Math::PI/2 + a) * r
        y2 = y - sin(Math::PI/2 + a) * r
        z2 = z
        x3 = x + cos(Math::PI/2 + 2*a) * r
        y3 = y - sin(Math::PI/2 + 2*a) * r
        z3 = z
      }

      isosceles_algorithm = proc { |x, y, z, r, a|
        a = a.to_rad
        h = (r+r/2) / sin(a/2) # sine law, bitches
        x1 = x + cos(Math::PI/2) * r
        y1 = y - sin(Math::PI/2) * r
        z1 = z
        x2 = x1 + cos(Math::PI + (Math::PI - a/2)) * h
        y2 = y1 - sin(Math::PI + (Math::PI - a/2)) * h
        z2 = z
        x3 = x1 + cos(a/2 - Math::PI) * h
        y3 = y1 - sin(a/2 - Math::PI) * h
        z3 = z
      }

      case args
      # equilateral triangle
      when Signature[[:x,:y,:z], :to_f]
        point, r = *args
        equilateral_algorithm.call point.x, point.y, point.z, r
        
      when Signature[[:x,:y], :to_f]
        point, r = *args
        equilateral_algorithm.call point.x, point.y, 0, r
        
      when Signature[:to_f, :to_f, :to_f]
        x, y, r = *args
        equilateral_algorithm.call x, y, 0, r

      # isosceles triangle
      when Signature[[:x,:y,:z], :to_f, :to_f]
        point, r, a = *args
        isosceles_algorithm.call point.x, point.y, point.z, r, a

      when Signature[[:x,:y], :to_f, :to_f]
        point, r, a = *args
        isosceles_algorithm.call point.x, point.y, 0, r, a

      when Signature[:to_f, :to_f, :to_f, :to_f]
        x, y, r, a = *args
        isosceles_algorithm.call x, y, 0, r, a

      # scalene triangle
      when Signature[[:x,:y,:z], [:x,:y,:z], [:x,:y,:z]]
        a, b, c = *args
        x1, y1, z1 = a.x, a.y, a.z
        x2, y2, z2 = b.x, b.y, b.z
        x3, y3, z3 = c.x, c.y, c.z

      when Signature[[:x,:y], [:x,:y], [:x,:y]]
        a, b, c = *args
        x1, y1 = a.x, a.y
        x2, y2 = b.x, b.y
        x3, y3 = c.x, c.y

      when Signature[:to_f, :to_f, :to_f, :to_f, :to_f, :to_f, :to_f, :to_f, :to_f]
        x1, y1, z1, x2, y2, z2, x3, y3, z3 = *args

      when Signature[:to_f, :to_f, :to_f, :to_f, :to_f, :to_f]
        x1, y1, x2, y2, x3, y3 = *args
      end

      Native.ofTriangle x1.to_f, y1.to_f, z1.to_f, x2.to_f, y2.to_f, z2.to_f, x3.to_f, y3.to_f, z3.to_f
    end

    # @overload ellipse x, y, width, height
    #   @demo Ellipse
    #     ellipse 50, 50, 80, 40
    # @overload ellipse x, y, z, width, height
    # @overload ellipse point, dimentions
    # @overload ellipse point, width, height
    # @overload ellipse x, y, dimentions
    def ellipse *args
      x = y = z = w = h = 0

      case args
      when Signature[[:x,:y], [:width,:height]]
        point, dim = *args
        x, y = point.x, point.y
        w, h = point.width, point.height

      when Signature[[:x,:y], :to_f, :to_f]
        point, w, h = *args
        x, y = point.x, point.y

      when Signature[:to_f, :to_f, [:width,:height]]
        x, y, dim = *args
        w, h = dim.width, dim.height

      when Signature[:to_f, :to_f, :to_f, :to_f]
        x, y, w, h = *args

      when Signature[:to_f, :to_f, :to_f, :to_f, :to_f]
        x, y, z, w, h = *args
      end

      Native.ofEllipse x.to_f, y.to_f, z.to_f, w.to_f, h.to_f
    end

    # @overload rounded_rectangle x, y, width, height, radius
    #   @demo Basic rounded rectangle
    #     rounded_rectangle 10, 10, 80, 80, 10
    # @overload rounded_rectangle x, y, z, width, height, radius
    def rounded_rectangle *args
      x = y = z = w = h = r = 0

      case args
      when Signature[[:x,:y,:z], [:width,:height], :to_f]
        point, dim, r = *args
        x, y, z = point.x, point.y, point.z
        w, h = dim.width, dim.height

      when Signature[[:x,:y], [:width,:height], :to_f]
        point, dim, r = *args
        x, y = point.x, point.y
        w, h = dim.width, dim.height

      when Signature[:to_f, :to_f, [:width,:height], :to_f]
        x, y, dim, r = *args
        w, h = dim.width, dim.height

      when Signature[[:x,:y], :to_f, :to_f, :to_f]
        point, w, h, r = *args
        x, y = point.x, point.y

      when Signature[:to_f, :to_f, :to_f, :to_f, :to_f]
        x, y, w, h, r = *args

      when Signature[:to_f, :to_f, :to_f, :to_f, :to_f, :to_f]
        x, y, z, w, h, r = *args
      end

      Native.ofRectRounded x.to_f, y.to_f, z.to_f, w.to_f, h.to_f, r.to_f
    end

    # @overload curve x0, y0, x1, y1, x2, y2, x3, y3
    #   @demo
    #     fill false
    #     curve 10, -100, 10, 50, 90, 50, 90, 200
    # @overload curve x0, y0, z0, x1, y1, z1, x2, y2, z2, x3, y3, z3
    # @overload curve point0, point1, point2, point3
    def curve *args
      x0 = y0 = z0 = x1 = y1 = z1 = x2 = y2 = z2 = x3 = y3 = z3 = 0

      case args
      when Signature[[:x,:y,:z], [:x,:y,:z], [:x,:y,:z], [:x,:y,:z]]
        a, b, c, d = *args
        x0, y0, z0 = a.x, a.y, a.z
        x1, y1, z1 = b.x, b.y, b.z
        x2, y2, z2 = c.x, c.y, c.z
        x3, y3, z3 = d.x, d.y, d.z

      when Signature[[:x,:y], [:x,:y], [:x,:y], [:x,:y]]
        a, b, c, d = *args
        x0, y0 = a.x, a.y
        x1, y1 = b.x, b.y
        x2, y2 = c.x, c.y
        x3, y3 = d.x, d.y

      when Signature[:to_f, :to_f, :to_f, :to_f, :to_f, :to_f, :to_f, :to_f]
        x0, y0, x1, y1, x2, y2, x3, y3 = *args

      when Signature[:to_f, :to_f, :to_f, :to_f, :to_f, :to_f, :to_f, :to_f, :to_f, :to_f, :to_f, :to_f]
        x0, y0, z0, x1, y1, z1, x2, y2, z2, x3, y3, z3 = *args
      end

      Native.ofCurve x0.to_f, y0.to_f, z0.to_f, x1.to_f, y1.to_f, z1.to_f, x2.to_f, y2.to_f, z2.to_f, x3.to_f, y3.to_f, z3.to_f
    end

    # @overload bezier x0, y0, x1, y1, x2, y2, x3, y3
    #   @demo Bezier curve
    #     fill false
    #     bezier 10, 10, 10, 50, 90, 50, 90, 90
    # 
    # @overload bezier x0, y0, z0, x1, y1, z1, x2, y2, z2, x3, y3, z3
    # @overload bezier point0, point1, point2, point3
    def bezier *args
      x0 = y0 = z0 = x1 = y1 = z1 = x2 = y2 = z2 = x3 = y3 = z3 = 0

      case args
      when Signature[[:x,:y,:z], [:x,:y,:z], [:x,:y,:z], [:x,:y,:z]]
        a, b, c, d = *args
        x0, y0, z0 = a.x, a.y, a.z
        x1, y1, z1 = b.x, b.y, b.z
        x2, y2, z2 = c.x, c.y, c.z
        x3, y3, z3 = d.x, d.y, d.z

      when Signature[[:x,:y], [:x,:y], [:x,:y], [:x,:y]]
        a, b, c, d = *args
        x0, y0 = a.x, a.y
        x1, y1 = b.x, b.y
        x2, y2 = c.x, c.y
        x3, y3 = d.x, d.y

      when Signature[:to_f, :to_f, :to_f, :to_f, :to_f, :to_f, :to_f, :to_f]
        x0, y0, x1, y1, x2, y2, x3, y3 = *args

      when Signature[:to_f, :to_f, :to_f, :to_f, :to_f, :to_f, :to_f, :to_f, :to_f, :to_f, :to_f, :to_f]
        x0, y0, z0, x1, y1, z1, x2, y2, z2, x3, y3, z3 = *args
      end

      Native.ofBezier x0.to_f, y0.to_f, z0.to_f, x1.to_f, y1.to_f, z1.to_f, x2.to_f, y2.to_f, z2.to_f, x3.to_f, y3.to_f, z3.to_f
    end

    def begin_shape
      Native.ofBeginShape
    end

    def end_shape close=true
      Native.ofEndShape close.to_bool
    end

    # @demo Star
    #   shape do
    #     vertex 50, 10
    #     vertex 40, 30
    #     vertex 10, 30
    #     vertex 40, 45
    #     vertex 20, 80
    #     vertex 50, 60
    #     vertex 80, 80
    #     vertex 60, 45
    #     vertex 90, 30
    #     vertex 60, 30
    #   end
    # 
    # @demo Wave
    #   fill false
    #   shape :open do
    #     width.to_i.times do |x|
    #       vertex x, 50 + sin(x / 4.0) * 10
    #     end
    #   end
    # 
    # @see #vertex, #curve_vertex, #begin_shape, #end_shape, #next_contour
    def shape close=:closed
      begin_shape
      yield
      end_shape close==:closed
    end

    def next_contour close=true
      Native.ofNextContour close.to_bool
    end

    def vertex *args
      x = y = z = 0

      case args
      when Signature[[:x,:y,:z]]
        x, y, z, = args.first.x, args.first.y, args.first.z

      when Signature[[:x,:y]]
        x, y = args.first.x, args.first.y

      when Signature[:to_f, :to_f]
        x, y = *args

      when Signature[:to_f, :to_f, :to_f]
        x, y, z = *args
      end

      Native.ofVertex x.to_f, y.to_f, z.to_f
    end

    # @overload curve_vertex x, y
    #   @demo Soft star
    #     shape do
    #       curve_vertex 50, 10
    #       curve_vertex 50, 10
    #       curve_vertex 40, 30
    #       curve_vertex 10, 30
    #       curve_vertex 40, 45
    #       curve_vertex 20, 80
    #       curve_vertex 50, 60
    #       curve_vertex 80, 80
    #       curve_vertex 60, 45
    #       curve_vertex 90, 30
    #       curve_vertex 60, 30
    #       curve_vertex 50, 10
    #     end
    # @overload curve_vertex point
    def curve_vertex *args
      x = y = 0

      case args
      when Signature[[:x,:y]]
        x, y = args.first.x, args.first.y

      when Signature[:to_f, :to_f]
        x, y = *args
      end

      Native.ofCurveVertex x.to_f, y.to_f
    end

    # @overload bezier_vertex x1, y1, x2, y2
    # @overload bezier_vertex x1, y1, z1, x2, y2, z2
    # @overload bezier_vertex point1, point2
    def bezier_vertex *args
      x1 = y1 = z1 = x2 = y2 = z2 = 0

      case args
      when Signature[[:x,:y,:z], [:x,:y,:z]]
        a, b = *args
        x1, y1, z1 = a.x, a.y, a.z
        x2, y2, z2 = b.x, b.y, b.z

      when Signature[[:x,:y], [:x,:y]]
        a, b = *args
        x1, y1 = a.x, a.y
        x2, y2 = b.x, b.y

      when Signature[:to_f, :to_f, :to_f, :to_f]
        x1, y1, x2, y2 = *args

      when Signature[:to_f, :to_f, :to_f, :to_f, :to_f, :to_f]
        x1, y1, z1, x2, y2, z2 = *args
      end
      
      Native.ofBezierVertex x1.to_f, y1.to_f, z1.to_f, x2.to_f, y2.to_f, z2.to_f
    end

    # @demo Wireframe Sphere
    #   fill false
    #   sphere 50, 50, 40
    def sphere *args
      x = y = z = r = 0

      case args
      when Signature[[:x,:y,:z], :to_f]
        p, r = *args
        x, y, z = p.x, p.y, p.z

      when Signature[[:x,:y], :to_f]
        p, r = *args
        x, y = p.x, p.y

      when Signature[:to_f, :to_f, :to_f]
        x, y, r = *args

      when Signature[:to_f, :to_f, :to_f, :to_f]
        x, y, z, r = *args
      end

      Native.ofSphere x.to_f, y.to_f, z.to_f, r.to_f
    end

    # @overload box x, y, size
    #   @demo Boxes in the corners
    #     fill false
    #     box 20, 20, 30
    #     box 20, 80, 30
    #     box 80, 20, 30
    #     box 80, 80, 30
    # @overload box x, y, z, size
    # @overload box center, size
    def box *args
      x = y = z = r = 0

      case args
      when Signature[[:x,:y,:z], :to_f]
        p, r = *args
        x, y, z = p.x, p.y, p.z

      when Signature[[:x,:y], :to_f]
        p, r = *args
        x, y = p.x, p.y

      when Signature[:to_f, :to_f, :to_f]
        x, y, r = *args

      when Signature[:to_f, :to_f, :to_f, :to_f]
        x, y, z, r = *args
      end

      Native.ofBox x.to_f, y.to_f, z.to_f, r.to_f
    end

    # @overload polygon_winding_mode mode
    # @overload polygon_winding_mode
    def polygon_winding_mode mode=nil
      @polygon_winding_mode ||= :odd # is this the default?

      if mode.present?
        @polygon_winding_mode = mode
        Native.ofSetPolyMode @polygon_winding_mode
      else
        @polygon_winding_mode
      end
    end

    def push_view
      Native.ofPushView
    end

    def pop_view
      Native.ofPopView
    end

    def view
      push_view
      yield
      pop_view
    end

    def viewport x=0.0, y=0.0, w=0.0, h=0.0, invert_y=true
      Native.ofViewport x.to_f, y.to_f, w.to_f, h.to_f, invert_y.to_bool
    end

    def viewport_height
      Native.ofGetViewportHeight
    end

    def viewport_width
      Native.ofGetViewportWidth
    end

    # @overload smoothing smooth
    # @overload smoothing
    def smoothing smooth=nil
      @smoothing_enabled ||= false

      if smooth.present?
        @smoothing_enabled = smooth.to_bool
        @smoothing_enabled ? Native.ofEnableSmoothing : Native.ofDisableSmoothing
      else
        @smoothing_enabled
      end
    end

    # @demo Single point
    #   point 50, 50
    def point x, y
      shape { vertex x, y; vertex x, y+1 }
    end

    # Reset graphics settings to Zajal's defaults
    def defaults
      alpha_blending false
      background :ketchup
      blend_mode :disabled
      circle_resolution 22
      clear_background true
      color_mode :rgb
      color :white
      curve_resolution 22
      fill true
      line_width 1
      point_sprites false
      polygon_winding_mode :odd
      rectangle_mode :corner
      smoothing false
      sphere_resolution 8
      Zajal::Graphics::Native.ofSetupScreenPerspective width.to_f, height.to_f, :default, false, 60.0, 0.0, 0.0
    end

    # @api internal
    def self.included sketch
      sketch.before_event :setup do
        defaults
      end

      sketch.after_event :setup do
        @defaults = {}
        %w[alpha_blending background blend_mode circle_resolution clear_background
          color curve_resolution fill line_width point_sprites polygon_winding_mode
          rectangle_mode smoothing sphere_resolution].each do |m|
          @defaults[m.to_sym] = self.send m.to_sym
        end
      end

      sketch.before_event :draw do
        Native.ofSetupScreen
        @defaults.each { |meth, val| self.send meth, val }
      end
    end

    # FFI hooks to Math::pIled openFrameworks functionality.
    # 
    # The methods in here do the actual work by invoking Math::pIled C++
    # functions in +libof.so+.
    # @api internal
    module Native
      extend FFI::Cpp::Library

      File.expand_path("lib/libof.so", File.dirname(__FILE__))

      enum :ofOrientation,
       [:default,
        :oneEighty,
        :ninety_left,
        :ninety_right,
        :unknown]
      enum :ofHandednessType,
       [:left,
        :right]
      enum :ofRectMode,
       [:corner,
        :center]
      enum :ofFillFlag,
       [:outline,
        :filled]
      enum :ofBlendMode,
       [:disabled,
        :alpha,
        :add,
        :subtract,
        :multiply,
        :screen]
      enum :ofPolyWindingMode,
       [:odd,
        :nonzero,
        :positive,
        :negative,
        :abs_geq_two]

      typedef :pointer, :ofRectangle
      typedef :pointer, :ofStyle

      # TODO technically, this is not a Graphics method. Move it.
      typedef :pointer, :ofAppBaseWindow
      attach_function :ofSetupOpenGL, [type(:ofAppBaseWindow).pointer, :int, :int, :int], :void

      # pdf screenshot
      attach_function :ofBeginSaveScreenAsPDF, [:stdstring, :bool, :bool, :ofRectangle], :void
      attach_function :ofEndSaveScreenAsPDF, [], :void

      #  view transformations
      attach_function :ofPushView, [], :void
      attach_function :ofPopView, [], :void

      #  matrices and viewport
      attach_function :ofViewport, [:float, :float, :float, :float, :bool], :void
      attach_function :ofSetupScreenPerspective, [:float, :float, :ofOrientation, :bool, :float, :float, :float], :void
      attach_function :ofSetupScreenOrtho, [:float, :float, :ofOrientation, :bool, :float, :float], :void
      attach_function :ofGetCurrentViewport, [], :ofRectangle
      attach_function :ofGetViewportWidth, [], :int
      attach_function :ofGetViewportHeight, [], :int
      attach_function :ofOrientationToDegrees, [:ofOrientation], :int
      attach_function :ofSetCoordHandedness, [:ofHandednessType], :void
      attach_function :ofGetCoordHandedness, [], :ofHandednessType

      # transformations
      attach_function :ofPushMatrix, [], :void # matrix, push_matrix
      attach_function :ofPopMatrix, [], :void # matrix, pop_matrix
      attach_function :ofTranslate, [:float, :float, :float], :void # translate
      attach_function :ofScale, [:float, :float, :float], :void # scale
      attach_function :ofRotate, [:float, :float, :float, :float], :void 
      attach_function :ofRotateX, [:float], :void
      attach_function :ofRotateY, [:float], :void
      attach_function :ofRotateZ, [:float], :void # rotate

      #  screen coordinates / default gl values
      attach_function :ofSetupGraphicDefaults, [], :void
      attach_function :ofSetupScreen, [], :void

      #  drawing modes
      attach_function :ofGetRectMode, [], :ofRectMode
      attach_function :ofSetCircleResolution, [:int], :void
      attach_function :ofSetCurveResolution, [:int], :void
      attach_function :ofSetSphereResolution, [:int], :void

      #  drawing options
      attach_function :ofNoFill, [], :void
      attach_function :ofFill, [], :void
      attach_function :ofGetFill, [], :ofFillFlag
      attach_function :ofSetLineWidth, [:float], :void

      #  color options
      attach_function :ofSetColor, [:int, :int, :int, :int], :void 
      attach_function :ofSetHexColor, [:int], :void

      #  Blending
      attach_function :ofEnableBlendMode, [:ofBlendMode], :void
      attach_function :ofDisableBlendMode, [], :void

      #  point
      attach_function :ofEnablePointSprites, [], :void
      attach_function :ofDisablePointSprites, [], :void

      #  transparency
      attach_function :ofEnableAlphaBlending, [], :void
      attach_function :ofDisableAlphaBlending, [], :void

      #  smooth 
      attach_function :ofEnableSmoothing, [], :void
      attach_function :ofDisableSmoothing, [], :void

      #  drawing style
      attach_function :ofGetStyle, [], :ofStyle
      attach_function :ofSetStyle, [:ofStyle], :void
      attach_function :ofPushStyle, [], :void
      attach_function :ofPopStyle, [], :void
      attach_function :ofSetPolyMode, [:ofPolyWindingMode], :void
      attach_function :ofSetRectMode, [:ofRectMode], :void

      #  background
      attach_function :ofBgColorPtr, [], :pointer
      attach_function :ofBackground, [:int, :int, :int, :int], :void
      attach_function :ofBackgroundHex, [:int, :int], :void
      # attach_function :ofBackgroundGradient, [const ofColor& start, const ofColor& end, ofGradientMode mode], :void
      attach_function :ofSetBackgroundColor, [:int, :int, :int, :int], :void
      attach_function :ofSetBackgroundColorHex, [:int, :int], :void
      attach_function :ofSetBackgroundAuto, [:bool], :void
      attach_function :ofClear, [:float, :float, :float, :float], :void
      attach_function :ofClearAlpha, [], :void
      attach_function :ofbClearBg, [], :bool

      #  geometry
      attach_function :ofTriangle, [:float, :float, :float, :float, :float, :float, :float, :float, :float], :void
      attach_function :ofCircle, [:float, :float, :float, :float], :void
      attach_function :ofEllipse, [:float, :float, :float, :float, :float], :void
      attach_function :ofLine, [:float, :float, :float, :float, :float, :float], :void
      attach_function :ofRect, [:float, :float, :float, :float, :float], :void
      attach_function :ofRectRounded, [:float, :float, :float, :float, :float, :float], :void
      attach_function :ofCurve, [:float, :float, :float, :float, :float, :float, :float, :float, :float, :float, :float, :float], :void
      attach_function :ofBezier, [:float, :float, :float, :float, :float, :float, :float, :float, :float, :float, :float, :float], :void

      # polygons
      attach_function :ofBeginShape, [], :void
      attach_function :ofVertex, [:float, :float, :float], :void
      attach_function :ofCurveVertex, [:float, :float], :void
      attach_function :ofBezierVertex, [:float, :float, :float, :float, :float, :float, :float, :float, :float], :void
      attach_function :ofEndShape, [:bool], :void
      attach_function :ofNextContour, [:bool], :void

      # 3d
      attach_function :ofSphere, [:float, :float, :float, :float], :void
      attach_function :ofBox, [:float, :float, :float, :float], :void
      attach_function :ofCone, [:float, :float, :float, :float, :float], :void
    end
  end
end