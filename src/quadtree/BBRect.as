/**
 * User: VirtualMaestro
 * Date: 08.01.13
 * Time: 21:50
 */
package quadtree
{
	/**
	 * Represents rectangle class.
	 */
	internal class BBRect
	{
		internal var leftTopX:Number = 0;
		internal var leftTopY:Number = 0;
		internal var rightBottomX:Number = 0;
		internal var rightBottomY:Number = 0;

		internal var width:Number = 0;
		internal var height:Number = 0;
		internal var halfWidth:Number = 0;
		internal var halfHeight:Number = 0;

		internal var centerX:Number = 0;
		internal var centerY:Number = 0;

		internal var greaterSide:Number = 0;

		/**
		 */
		public function BBRect(p_x:Number = 0, p_y:Number = 0, p_width:Number = 0, p_height:Number = 0)
		{
			set(p_x, p_y, p_width, p_height);
		}
		
		/**
		 * Set initialization parameters for rect - left corner position and size.
		 */
		[Inline]
		final public function set(p_x:Number = 0, p_y:Number = 0, p_width:Number = 0, p_height:Number = 0):BBRect
		{
			leftTopX = p_x;
			leftTopY = p_y;
			width = p_width;
			height = p_height;
			halfWidth = p_width*0.5;
			halfHeight = p_height*0.5;
			centerX = p_x + halfWidth;
			centerY = p_y + halfHeight;
			rightBottomX = p_x + p_width;
			rightBottomY = p_y + p_height;
			greaterSide = (p_width > p_height) ? p_width : p_height;

			return this;
		}

		/**
		 * Set left-top X and left-top Y.
		 */
		public function setXY(p_x:Number, p_y:Number):void
		{
			leftTopX = p_x;
			leftTopY = p_y;
			centerX = p_x + halfWidth;
			centerY = p_y + halfHeight;
			rightBottomX = p_x + width;
			rightBottomY = p_y + height;
		}

		/**
		 * Sets center position of rect.
		 */
		protected function setCenterXY(p_x:Number, p_y:Number):void
		{
			centerX = p_x;
			centerY = p_y;
			leftTopX = p_x - halfWidth;
			leftTopY = p_y - halfHeight;
			rightBottomX = p_x + halfWidth;
			rightBottomY = p_y + halfHeight;
		}

		/**
		 * Sets new size for rect.
		 */
		public function setSize(p_width:Number, p_height:Number):void
		{
			width = p_width;
			height = p_height;
			halfWidth = p_width*0.5;
			halfHeight = p_height*0.5;
			centerX = leftTopX + halfWidth;
			centerY = leftTopY + halfHeight;
			rightBottomX = leftTopX + p_width;
			rightBottomY = leftTopY + p_height;
			greaterSide = (p_width > p_height) ? p_width : p_height
		}

		/**
		 * Method returns true if current rect is fully inside in given rect.
		 */
		[Inline]
		final public function isInside(p_rect:BBRect):Boolean
		{
			if (leftTopX >= p_rect.leftTopX)
			{
				if (leftTopY >= p_rect.leftTopY)
				{
					if (rightBottomX <= p_rect.rightBottomX)
					{
						if (rightBottomY <= p_rect.rightBottomY) return true;
					}
				}
			}

			return false;
		}

		/**
		 * Returns true if current rect is intersected with given rect.
		 */
		[Inline]
		final public function isIntersect(p_rect:BBRect):Boolean
		{
			var ltx:Number = p_rect.leftTopX;
			var lty:Number = p_rect.leftTopY;
			var rbx:Number = p_rect.rightBottomX;
			var rby:Number = p_rect.rightBottomY;

			var exp:Boolean = false;

			if (leftTopX >= ltx)
			{
				if (leftTopX <= rbx) exp = true;
			}

			if (!exp)
			{
				if (ltx >= leftTopX)
				{
					if (!(ltx <= rightBottomX)) return false;
				}
				else return false;
			}

			if (leftTopY >= lty)
			{
				if (leftTopY <= rby) return true;
			}

			if (lty >= leftTopY)
			{
				if (lty <= rightBottomY) return true;
			}

			return false;
		}
	}
}
