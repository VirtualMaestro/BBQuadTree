package quadtree
{
	/**
	 * @author VirtualMaestro
	 */
	public class BBQuadNode extends BBRect
	{
		// need for pool
		private var next:BBQuadNode = null;

		//
		internal var parent:BBQuadNode = null;
		internal var depth:int = 0;
		internal var numberQuadrant:int = 0;

		// children nodes
		internal var hasChildrenNodes:Boolean = false;
		internal var leftTopNode:BBQuadNode = null;
		internal var rightTopNode:BBQuadNode = null;
		internal var rightBottomNode:BBQuadNode = null;
		internal var leftBottomNode:BBQuadNode = null;

		//
		internal var boxesListHead:BBBox = null;
		internal var boxesListTail:BBBox = null;
		internal var numBoxes:int = 0;
		internal var numChildrenBoxes:int = 0; // number of boxes in first layer children

		internal var tree:BBQuadTree = null;
		internal var isDisposed:Boolean = false;

		/**
		 * Constructor
		 */
		public function BBQuadNode(p_leftTopX:Number = 0, p_leftTopY:Number = 0, p_size:Number = 10)
		{
			super(p_leftTopX, p_leftTopY, p_size, p_size);
		}

		/**
		 */
		[Inline]
		final internal function isChildrenHasChildren():Boolean
		{
			return hasChildrenNodes && (leftTopNode.hasChildrenNodes || leftBottomNode.hasChildrenNodes || rightTopNode.hasChildrenNodes || rightBottomNode.hasChildrenNodes);
		}

		/**
		 * Adds box to node.
		 */
		[Inline]
		final internal function addBox(p_box:BBBox):void
		{
			if (boxesListTail)
			{
				boxesListTail.next = p_box;
				p_box.prev = boxesListTail;
				boxesListTail = p_box;
			}
			else boxesListHead = boxesListTail = p_box;

			p_box.node = this;

			numBoxes++;
			if (parent) parent.numChildrenBoxes++;
		}

		/**
		 * Unlink given box from this node.
		 */
		[Inline]
		final internal function unlinkBox(p_box:BBBox):void
		{
			if (p_box == boxesListHead)
			{
				boxesListHead = boxesListHead.next;
				if (boxesListHead == null) boxesListTail = null;
				else boxesListHead.prev = null;
			}
			else if (p_box == boxesListTail)
			{
				boxesListTail = boxesListTail.prev;
				if (boxesListTail == null) boxesListHead = null;
				else boxesListTail.next = null;
			}
			else
			{
				var prevBox:BBBox = p_box.prev;
				var nextBox:BBBox = p_box.next;
				prevBox.next = nextBox;
				nextBox.prev = prevBox;
			}

			p_box.prev = null;
			p_box.next = null;
			p_box.node = null;

			numBoxes--;
			if (parent) parent.numChildrenBoxes--;
		}

		/**
		 * Method assumes that children are exist.
		 */
		final internal function getExistOneChildrenBox():BBBox
		{
			if (leftTopNode.numBoxes > 0) return leftTopNode.boxesListHead;
			else if (leftBottomNode.numBoxes > 0) return leftBottomNode.boxesListHead;
			else if (rightTopNode.numBoxes > 0) return rightTopNode.boxesListHead;
			return rightBottomNode.boxesListHead;
		}

		/**
		 */
		[Inline]
		final internal function getChildNodeContainedBox(p_box:BBBox):BBQuadNode
		{
			if (depth >= tree.maxDepth) return null;
			
			var bLeftTopX:Number = p_box.leftTopX;
			var bLeftTopY:Number = p_box.leftTopY;
			var bRightBottomX:Number = p_box.rightBottomX;
			var bRightBottomY:Number = p_box.rightBottomY;

			var nCenterX:Number = centerX;
			var nCenterY:Number = centerY;

			var resultNode:BBQuadNode = null;

			if (bRightBottomY <= nCenterY) // бокс полностью находится в верхней части нода
			{
				if (bRightBottomX <= nCenterX)  // бокс полностью находится в 1-м квадранте
				{
					addChildrenNodes();
					resultNode = leftTopNode;
				}
				else if (bLeftTopX >= nCenterX)  // бокс полностью находится во 2-м квадранте
				{
					addChildrenNodes();
					resultNode = rightTopNode;
				}
//						else ;                              // бокс пересекается с первым и вторым квадрантом
			}
			else        // как минимум нижняя часть бокса в нижней части нода
			{
				if (bLeftTopY >= nCenterY)  // бокс полностью находится в нижней части нода
				{
					if (bRightBottomX <= nCenterX)   // бокс полностью находится в 3-м квадранте
					{
						addChildrenNodes();
						resultNode = leftBottomNode;
					}
					else if (bLeftTopX >= nCenterX)  // бокс полностью находится в 4-м квадранте
					{
						addChildrenNodes();
						resultNode = rightBottomNode;
					}
//							else ;                               // бокс пересекается с 3 и 4-м квадрантами
				}
//						else ;                         // бокс пересекается верхней и нижней частью нода
			}

			return resultNode;
		}

		/**
		 * Removes children nodes.
		 */
		[Inline]
		final internal function removeChildrenNodes():void
		{
			if (hasChildrenNodes)
			{
				leftTopNode.dispose();
				leftTopNode = null;
				leftBottomNode.dispose();
				leftBottomNode = null;
				rightTopNode.dispose();
				rightTopNode = null;
				rightBottomNode.dispose();
				rightBottomNode = null;

				hasChildrenNodes = false;
			}
		}

		/**
		 * Adds four nodes.
		 */
		[Inline]
		final internal function addChildrenNodes():void
		{
			if (!hasChildrenNodes)
			{
				var nSize:Number = greaterSide * 0.5;
				var nDepth:int = depth+1;
				var nX:Number;
				var nY:Number;

				// Left top
				nX = leftTopX;
				nY = leftTopY;
				leftTopNode = get(nX, nY, nSize);
				leftTopNode.parent = this;
				leftTopNode.depth = nDepth;
				leftTopNode.tree = tree;
				leftTopNode.numberQuadrant = 1;

				// Right top
				nX = nX + nSize;
				rightTopNode = get(nX, nY, nSize);
				rightTopNode.parent = this;
				rightTopNode.depth = nDepth;
				rightTopNode.tree = tree;
				rightTopNode.numberQuadrant = 2;

				// Right bottom
				nY = nY + nSize;
				rightBottomNode = get(nX, nY, nSize);
				rightBottomNode.parent = this;
				rightBottomNode.depth = nDepth;
				rightBottomNode.tree = tree;
				rightBottomNode.numberQuadrant = 4;

				// Left bottom
				nX = leftTopX;
				leftBottomNode = get(nX, nY, nSize);
				leftBottomNode.parent = this;
				leftBottomNode.depth = nDepth;
				leftBottomNode.tree = tree;
				leftBottomNode.numberQuadrant = 3;

				hasChildrenNodes = true;
			}
		}

		/**
		 * Update depth index. Useful when expands tree happened.
		 */
		final internal function updateDepth():void
		{
			if (parent) depth = parent.depth+1;

			if (hasChildrenNodes)
			{
				leftTopNode.updateDepth();
				leftBottomNode.updateDepth();
				rightTopNode.updateDepth();
				rightBottomNode.updateDepth();
			}
		}

		/**
		 * Fills container all boxed which in current and children nodes.
		 */
		[Inline]
		final internal function getBranchBoxes(p_boxesContainer:Vector.<BBBox>):void
		{
			// gets boxes
			if (boxesListHead)
			{
				var box:BBBox = boxesListHead;
				while(box)
				{
					p_boxesContainer[p_boxesContainer.length] = box;
					box = box.next;
				}
			}

			// goes to children
			if (hasChildrenNodes)
			{
				leftTopNode.getBranchBoxes(p_boxesContainer);
				rightTopNode.getBranchBoxes(p_boxesContainer);
				leftBottomNode.getBranchBoxes(p_boxesContainer);
				rightBottomNode.getBranchBoxes(p_boxesContainer);
			}
		}

		/**
		 * Dispose the node and returns to the pool.
		 */
		[Inline]
		final internal function dispose():void
		{
			isDisposed = true;
			
			// dispose the children-boxes
			if (numBoxes > 0)
			{
				var box:BBBox = boxesListHead;
				var curBox:BBBox;
				while(box)
				{
					curBox = box;
					box = box.next;
					curBox.dispose();
				}
			}
			
			boxesListHead = null;
			boxesListTail = null;
			numBoxes = 0;
			numChildrenBoxes = 0;

			// dispose the node children
			removeChildrenNodes();

			// nullify node's properties
			parent = null;
			depth = 0;
			numberQuadrant = 0;

			// put to pool
			put(this);
		}

		//////////////////////
		// POOL SYSTEM ///////
		//////////////////////

		//
		static private var _pool:BBQuadNode = null;

		/**
		 * Returns node. Uses pool or creates new instance.
		 */
		static public function get(p_leftTopX:Number = 0, p_leftTopY:Number = 0, p_size:Number = 10):BBQuadNode
		{
			var node:BBQuadNode;
			if (_pool)
			{
				node = _pool;
				_pool = _pool.next;
				node.next = null;
				node.set(p_leftTopX, p_leftTopY, p_size, p_size);
				node.isDisposed = false;
			}
			else node = new BBQuadNode(p_leftTopX, p_leftTopY, p_size);

			return node;
		}

		/**
		 * Put node to pool.
		 */
		[Inline]
		static internal function put(p_node:BBQuadNode):void
		{
			if (_pool) p_node.next = _pool;
			else p_node.next = null;
			
			_pool = p_node
		}

		/**
		 * Clear pool.
		 */
		static internal function rid():void
		{
			if (_pool)
			{
				_pool.next = null;
				_pool = null;
			}
		}
	}
}
