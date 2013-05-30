package quadtree
{
	/**
	 *
	 */
	public class BBBox extends BBRect
	{
		internal var node:BBQuadNode = null;
		internal var next:BBBox = null;
		internal var prev:BBBox = null;

		//
		public var userData:Object;
		public var disposeCallback:Function;
		private var _isDispose:Boolean = false;

		/**
		 */
		public function BBBox(p_widthBox:Number = 10, p_heightBox:Number = 10, p_x:Number = 0, p_y:Number = 0)
		{
			setPosAndSize(p_x, p_y, p_widthBox, p_heightBox);
		}

		/**
		 * Position is center of box.
		 */
		public function setPosition(p_x:Number, p_y:Number):void
		{
			setCenterXY(p_x,  p_y);
			update();
		}

		/**
		 * Shifts position by given number.
		 */
		public function shiftPosition(shiftX:Number, shiftY:Number):void
		{
			setPosition(centerX+shiftX, centerY+shiftY);
		}

		/**
		 * Set new size for box.
		 */
		override public function setSize(p_widthBox:Number, p_heightBox:Number):void
		{
			if (width == p_widthBox && height == p_heightBox) return;
			super.setSize(p_widthBox, p_heightBox);
			update();
		}

		/**
		 * Set position and size at the same time.
		 */
		public function setPosAndSize(p_x:Number, p_y:Number, p_widthBox:Number, p_heightBox:Number):void
		{
			if (!(width == p_widthBox && height == p_heightBox))
			{
				super.setSize(p_widthBox, p_heightBox);
			}

			setCenterXY(p_x,  p_y);

			update();
		}

		/**
		 */
		[Inline]
		final private function update():void
		{
			if (node) node.tree.update(this);
		}
		
		/**
		 */
		public function get x():Number
		{
			return centerX;
		}
		
		/**
		 */
		public function get y():Number
		{
			return centerY;
		}
		
		/**
		 */
		public function get widthBox():Number
		{
			return width;
		}
		
		/**
		 */
		public function get heightBox():Number
		{
			return height;
		}
		
//		/**
//		 */
//		internal function isEntireInNode():Boolean
//		{
//			return isInside(node);
//		}

		/**
		 * Disposes the box and back it to the pool.
		 */
		public function dispose():void
		{
			trace("Try to dispose box");
			
			if (!_isDispose)
			{
				_isDispose = true;
				
				if (node) 
				{
					var tNode:BBQuadNode = node;
					node.unlinkBox(this);
					tNode.tree.cleanBranch(tNode);
					tNode.tree.checkNodeMoveUpPretender(tNode);
				}
				
				//
				if (disposeCallback != null) disposeCallback(this);
				disposeCallback = null;

				// back to pool
				put(this);
			}
		}

		//////////////////////
		// POOL SYSTEM ///////
		//////////////////////

		//
		static private var _pool:BBBox = null;

		/**
		 * Returns box. Uses pool or creates new instance.
		 */
		static internal function get(p_width:Number = 10, p_height:Number = 10, p_x:Number = 0, p_y:Number = 0):BBBox
		{
			var box:BBBox;
			if (_pool)
			{
				box = _pool;
				_pool = _pool.next;
				
				box.next = null;
				box._isDispose = false;
				box.setPosAndSize(p_x, p_y, p_width, p_height);
			}
			else box = new BBBox(p_width, p_height, p_x, p_y);

			return box;
		}

		/**
		 * Put box to pool.
		 */
		static internal function put(p_box:BBBox):void
		{
			if (_pool) p_box.next = _pool;
			_pool = p_box;
		}
		
		/**
		 * Pre-cache given number of boxes.
		 */
		static public function preCache(p_numBoxes:int):void
		{
			for (var i:int = 0; i < p_numBoxes; i++) 
			{
				put(new BBBox());
			}
		}

		/**
		 * Clear pool.
		 */
		static internal function rid():void
		{
			if (_pool)
			{
				_pool.prev = null;
				_pool.next = null;
				_pool = null;
			}
		}
	}
}
