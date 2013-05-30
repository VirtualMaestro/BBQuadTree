package quadtree
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;

	/**
	 * For debug drawing of quad tree.
	 */
	public class BBQuadTreeDebugDraw extends Sprite
	{
		public var isWire:Boolean = false;

		private var _enable:Boolean = true;

		private var _tree:BBQuadTree;

		private var _colors:Array;

		private var _canvas:BitmapData;
		private var _canvasRect:Rectangle;

		private var _rect:Rectangle;
		private var _width:Number;
		private var _height:Number;
		private var _scissorTest:Boolean = false;
		private var _scissorFrame:BBRect;
		private var _nodeRect:BBRect;

		/**
		 */
		public function BBQuadTreeDebugDraw(p_quadTree:BBQuadTree, p_width:Number = 800, p_height:Number = 600)
		{
			_tree = p_quadTree;
			_width = p_width;
			_height = p_height;
			_rect = new Rectangle();
			_nodeRect = new BBRect();
			_scissorFrame = new BBRect(0, 0, p_width, p_height);

			//
			_colors = [];
			_colors[0] = 0xff437eb1;
			_colors[1] = 0xff6cbdd4;
			_colors[2] = 0xff107b48;
			_colors[3] = 0xff908d41;
			_colors[4] = 0xfff1d41c;
			_colors[5] = 0xfff68e2b;
			_colors[6] = 0xff7e6199;
			_colors[7] = 0xff591044;
			_colors[8] = 0xff87212a;
			_colors[9] = 0xff000000;
			_colors[10] = 0xff555555;

			//
			_canvas = new BitmapData(_width, _height, false);
			var containerCanvas:Bitmap = new Bitmap(_canvas);
			_canvasRect = _canvas.rect;
			addChild(containerCanvas);

			//
			addEventListener(Event.ENTER_FRAME, loop);
		}

		/**
		 */
		private function loop(event:Event):void
		{
			if (_enable)
			{
				_scissorTest = _tree.size > _width;
				drawTree(_tree);
			}
		}

		/**
		 */
		public function set enable(p_val:Boolean):void
		{
			_enable = p_val;
			if (!_enable) _canvas.fillRect(_canvasRect, 0xFFFFFFFF);
		}

		/**
		 */
		public function get enable():Boolean
		{
			return _enable;
		}

		/**
		 */
		public function get colors():Array
		{
			return _colors;
		}

		/**
		 * Clear drawing canvas.
		 */
		public function clear():void
		{
			_canvas.fillRect(_canvasRect, 0xFFFFFFFF);
		}

		/**
		 * Draw quad-tree.
		 */
		private function drawTree(p_quadTree:BBQuadTree):void
		{
			_canvas.lock();
			clear();
			drawNode(p_quadTree.root);
			_canvas.unlock();
		}

		/**
		 */
		private function drawNode(p_node:BBQuadNode):void
		{
			var color:uint = _colors[p_node.depth];

			// draw node
			drawRect(p_node.leftTopX, p_node.leftTopY, p_node.rightBottomX, p_node.rightBottomY, color, true);

			// draw node's children
			if (p_node.hasChildrenNodes)
			{
				drawNode(p_node.leftTopNode);
				drawNode(p_node.leftBottomNode);
				drawNode(p_node.rightTopNode);
				drawNode(p_node.rightBottomNode);
			}

			// draw node's boxes
			if (p_node.numBoxes > 0)
			{
				var box:BBBox = p_node.boxesListHead;
				while (box)
				{
					drawRect(box.leftTopX, box.leftTopY, box.rightBottomX, box.rightBottomY, color, isWire);
					box = box.next;
				}
			}
		}

		/**
		 */
		public function drawRect(tlX:Number, tlY:Number, rbX:Number, rbY:Number, color:uint = 0xff000000, isWire:Boolean = true):void
		{
			if (_scissorTest)
			{
				_nodeRect.set(tlX, tlY, rbX - tlX, rbY - tlY);

				if (_scissorFrame.isIntersect(_nodeRect))
				{
					_rect.setTo(tlX, tlY, rbX - tlX, rbY - tlY);
					isWire ? drawRectWire(_rect, color) : _canvas.fillRect(_rect, color);
				}
			}
			else
			{
				_rect.setTo(tlX, tlY, rbX - tlX, rbY - tlY);
				isWire ? drawRectWire(_rect, color) : _canvas.fillRect(_rect, color);
			}
		}

		/**
		 */
		public function drawBox(p_box:BBBox, p_isWire:Boolean = false):void
		{
			drawRect(p_box.leftTopX, p_box.leftTopY, p_box.rightBottomX, p_box.rightBottomY, _colors[p_box.node.depth], p_isWire);
		}

		/**
		 */
		private function drawRectWire ( rect:Rectangle, color:uint ):void
		{
			var rX:Number = rect.x;
			var rY:Number = rect.y;
			var rWidth:Number = rect.width;
			var rHeight:Number = rect.height;
			var rX_add_Width:Number = rX+rWidth;
			var rY_add_Height:Number = rY+rHeight;

			line ( rX, rY, rX_add_Width, rY, color );
			line ( rX_add_Width, rY, rX_add_Width, rY_add_Height, color );
			line ( rX_add_Width, rY_add_Height, rX, rY_add_Height, color );
			line ( rX, rY_add_Height, rX, rY, color );
		}

		/**
		 */
		private function line ( x0:int, y0:int, x1:int, y1:int, color:uint ):void
		{
			var dx:int;
			var dy:int;
			var i:int;
			var xinc:int;
			var yinc:int;
			var cumul:int;
			var x:int;
			var y:int;
			x = x0;
			y = y0;
			dx = x1 - x0;
			dy = y1 - y0;
			xinc = ( dx > 0 ) ? 1 : -1;
			yinc = ( dy > 0 ) ? 1 : -1;
			dx = dx < 0 ? -dx : dx;
			dy = dy < 0 ? -dy : dy;
			_canvas.setPixel32(x,y,color);

			if ( dx > dy )
			{
				cumul = dx >> 1;
		  		for ( i = 1 ; i <= dx ; ++i )
				{
					x += xinc;
					cumul += dy;
					if (cumul >= dx)
					{
			  			cumul -= dx;
			  			y += yinc;
					}
					_canvas.setPixel32(x,y,color);
				}
			}else
			{
		  		cumul = dy >> 1;
		  		for ( i = 1 ; i <= dy ; ++i )
				{
					y += yinc;
					cumul += dx;
					if ( cumul >= dy )
					{
			  			cumul -= dy;
			  			x += xinc ;
					}
					_canvas.setPixel32(x,y,color);
				}
			}
		}
	}
}
