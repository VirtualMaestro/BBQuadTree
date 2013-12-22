package quadtree
{
	/**
	 * @author VirtualMaestro
	 */
	public class BBQuadTree
	{
		public var maxDepth:int = 6;
		public var autoExpanding:Boolean = true;

		//
		private var _root:BBQuadNode = null;
		private var _queueUpdate:Vector.<BBBox> = null;
		private var _queueUpdateLen:int = 0;

		//
		private var _queryRect:BBRect;
		private var _result:Vector.<BBBox>;

		/**
		 * p_startX, p_startY - left top corner.
		 * p_quadSize - assumed quad size.
		 */
		public function BBQuadTree(p_quadSize:int, p_startX:Number = 0, p_startY:Number = 0)
		{
			_root = BBQuadNode.get(p_startX, p_startY, p_quadSize);
			_root.tree = this;

			_queueUpdate = new Vector.<BBBox>(20);

			//
			_queryRect = new BBRect();
			_result = new <BBBox>[];
		}

		/**
		 * Убрать передачу бокса на прямую, это позволит создавать бокс внутри системы с использованием пула.
		 * Первый параметр объект, второй размер коробки, третий позиция - возвращает созданный бокс в дереве.
		 */
		public function add(p_width:Number, p_height:Number, p_x:Number = 0, p_y:Number = 0):BBBox
		{
			var updateBox:BBBox = _root.numBoxes == 1 ? _root.boxesListHead : null;
			var box:BBBox = BBBox.get(p_width, p_height, p_x, p_y);
			_root.addBox(box);
			update(box);

			if (updateBox) update(updateBox);

			return box;
		}

		/**
		 */
		[Inline]
		final internal function update(p_box:BBBox):void
		{
			var node:BBQuadNode = p_box.node;
			if (p_box.isInside(node))
			{
				if (node.depth < maxDepth && node.halfWidth >= p_box.greaterSide && (node.numBoxes > 1 || node.hasChildrenNodes))
				{
					moveDeeper(p_box);
				}
			}
			else moveUpper(p_box);
		}

		/**
		 */
		[Inline]
		final private function updateBoxesInQueue():void
		{
			while (_queueUpdateLen > 0)
			{
				update(_queueUpdate[--_queueUpdateLen]);
			}
		}

		/**
		 */
		[Inline]
		final private function moveDeeper(p_box:BBBox):void
		{
			var currentNode:BBQuadNode = p_box.node;
			var boxGreaterSide:Number = p_box.greaterSide;
			var resultNode:BBQuadNode = currentNode;
			var iteratorNode:BBQuadNode = currentNode;

			for (; ;)
			{
				iteratorNode = iteratorNode.getChildNodeContainedBox(p_box);

				if (iteratorNode)
				{
					resultNode = iteratorNode;

					if ((resultNode.numBoxes == 0 && !resultNode.hasChildrenNodes) || resultNode.halfWidth < boxGreaterSide || resultNode.depth >= maxDepth) break;
					else if (resultNode.numBoxes == 1) _queueUpdate[_queueUpdateLen++] = resultNode.boxesListHead;
				}
				else break;
			}

			//
			if (resultNode != currentNode)
			{
				if (resultNode.numBoxes == 1) _queueUpdate[_queueUpdateLen++] = resultNode.boxesListHead;

				currentNode.unlinkBox(p_box);
				resultNode.addBox(p_box);

				//
				updateBoxesInQueue();

				if (currentNode.numBoxes == 1)
				{
					update(currentNode.boxesListHead);
				}
			}
		}

		/**
		 */
		[Inline]
		final private function moveUpper(p_box:BBBox):void
		{
			var currentNode:BBQuadNode = p_box.node;
			var parentNode:BBQuadNode = currentNode;
			var resultNode:BBQuadNode;

			currentNode.unlinkBox(p_box);

			for (; ;)
			{
				parentNode = parentNode.parent;

				if (parentNode)
				{
					if (p_box.isInside(parentNode))
					{
						resultNode = parentNode;
						break;
					}
				}
				else
				{
					resultNode = expandingTree(p_box);
					if (!resultNode) currentNode = cleanBranch(currentNode);
					if (currentNode) checkNodeMoveUpPretender(currentNode);
					break;
				}
			}

			if (resultNode)
			{
				resultNode.addBox(p_box);

				cleanBranch(currentNode);
				checkNodeMoveUpPretender(currentNode);
			}
		}

		/**
		 */
		[Inline]
		final internal function checkNodeMoveUpPretender(currentNode:BBQuadNode):void
		{
			if (!currentNode.isDisposed)
			{
				var parentNode:BBQuadNode = currentNode.parent;
				var parentBoxes:int = 0;
				var parentChildrenBoxes:int = 0;
				var currentBoxes:int = currentNode.numBoxes;

				if (parentNode)
				{
					parentBoxes = parentNode.numBoxes;
					parentChildrenBoxes = parentNode.numChildrenBoxes;
				}

				if (currentBoxes == 0)
				{
					if (currentNode.hasChildrenNodes) // проверяем дочерних нодах
					{
						if (currentNode.numChildrenBoxes == 1 && !currentNode.isChildrenHasChildren())
						{
							tryMoveUpper(currentNode.getExistOneChildrenBox());
						}
					}
					else
					{
						if (parentBoxes == 0 && parentChildrenBoxes == 1 && !parentNode.isChildrenHasChildren())
						{
							tryMoveUpper(parentNode.getExistOneChildrenBox());
						}
					}

					if (parentBoxes == 1)
					{
						if (parentChildrenBoxes == 0 && !parentNode.isChildrenHasChildren())
						{
							tryMoveUpper(parentNode.boxesListHead);
						}
					}
				}
				else if (currentBoxes == 1)
				{
					if (!currentNode.hasChildrenNodes && parentBoxes == 0 && parentNode && parentNode.numChildrenBoxes == 1 && !parentNode.isChildrenHasChildren())
					{
						tryMoveUpper(currentNode.boxesListHead);
					}
				}
			}
		}

		/**
		 */
		[Inline]
		final private function tryMoveUpper(p_box:BBBox):void
		{
			var currentNode:BBQuadNode = p_box.node;
			var parentNode:BBQuadNode = currentNode;

			while (1)
			{
				parentNode = parentNode.parent;

				if (parentNode && !currentNode.hasChildrenNodes &&
						parentNode.numBoxes == 0 && parentNode.numChildrenBoxes == 1 && !parentNode.isChildrenHasChildren())
				{
					currentNode.unlinkBox(p_box);
					currentNode = parentNode;
					currentNode.addBox(p_box);
					currentNode.removeChildrenNodes();
				}
				else break;
			}
		}

		/**
		 * Try to clean branch of given node (as leaf - branch removes upper).
		 * Return last parent (its children were removed).
		 */
		[Inline]
		final internal function cleanBranch(p_node:BBQuadNode):BBQuadNode
		{
			if (p_node.numBoxes > 0 || p_node.hasChildrenNodes) return p_node;

			while (1)
			{
				p_node = p_node.parent;

				if (p_node && p_node.numChildrenBoxes == 0 && !p_node.isChildrenHasChildren())
				{
					p_node.removeChildrenNodes();
				}
				else break;
			}

			return p_node;
		}

		/**
		 * Expanding tree if current not enough.
		 * box - object which request expanding.
		 * Returns new node (root) which fully contains the box, if expanding is not allow, returns null.
		 */
		internal function expandingTree(box:BBBox):BBQuadNode
		{
			if (autoExpanding)
			{
				// until object is completely contained in main node, expand the tree
				while (!box.isInside(_root))
				{
					expand(box);
				}
				return _root;
			}
			else box.dispose();

			return null;
		}

		/**
		 */
		private function expand(p_box:BBBox):void
		{
			var bCenterX:Number = p_box.centerX;
			var bCenterY:Number = p_box.centerY;
			var treeSize:Number = _root.greaterSide;

			var leftTopX:Number = _root.leftTopX;
			var leftTopY:Number = _root.leftTopY;

			var leftBottomX:Number = _root.leftTopX;
			var leftBottomY:Number = _root.leftTopY + treeSize;

			var rightTopX:Number = _root.leftTopX + treeSize;
			var rightTopY:Number = _root.leftTopY;

			var rightBottomX:Number = _root.leftTopX + treeSize;
			var rightBottomY:Number = _root.leftTopY + treeSize;

			var leftTopLen:Number = getDistance(leftTopX, leftTopY, bCenterX, bCenterY);
			var leftBottomLen:Number = getDistance(leftBottomX, leftBottomY, bCenterX, bCenterY);
			var rightTopLen:Number = getDistance(rightTopX, rightTopY, bCenterX, bCenterY);
			var rightBottomLen:Number = getDistance(rightBottomX, rightBottomY, bCenterX, bCenterY);

			var l:Number = (leftTopLen < leftBottomLen) ? leftTopLen : leftBottomLen;
			var r:Number = (rightTopLen < rightBottomLen) ? rightTopLen : rightBottomLen;
			var result:Number = (l < r) ? l : r;

			var newRootNode:BBQuadNode = BBQuadNode.get();
			newRootNode.setSize(treeSize * 2, treeSize * 2);
			newRootNode.tree = this;

			switch (result)
			{
				case leftTopLen:
				{
					newRootNode.setXY(leftTopX - treeSize, leftTopY - treeSize);
					newRootNode.addChildrenNodes();
					newRootNode.rightBottomNode.dispose();
					newRootNode.rightBottomNode = _root;

					break;
				}

				case leftBottomLen:
				{
					newRootNode.setXY(leftBottomX - treeSize, leftBottomY - treeSize);
					newRootNode.addChildrenNodes();
					newRootNode.rightTopNode.dispose();
					newRootNode.rightTopNode = _root;

					break;
				}

				case rightTopLen:
				{
					newRootNode.setXY(rightTopX - treeSize, rightTopY - treeSize);
					newRootNode.addChildrenNodes();
					newRootNode.leftBottomNode.dispose();
					newRootNode.leftBottomNode = _root;

					break;
				}

				case rightBottomLen:
				{
					newRootNode.setXY(rightBottomX - treeSize, rightBottomY - treeSize);
					newRootNode.addChildrenNodes();
					newRootNode.leftTopNode.dispose();
					newRootNode.leftTopNode = _root;

					break;
				}
			}

			// increment max depth, due to expanding brings new depth level
			maxDepth++;

			_root.parent = newRootNode;
			_root = newRootNode;
			_root.updateDepth();
		}

		/**
		 * Returns boxes which in given rect.
		 * Parameters is rectangle with left-top point and right-bottom point.
		 */
		public function get(p_ltX:Number, p_ltY:Number, p_rbX:Number, p_rbY:Number):Vector.<BBBox>
		{
			_result.length = 0;

			_queryRect.set(p_ltX, p_ltY, p_rbX - p_ltX, p_rbY - p_ltY);

			if (_queryRect.isInside(_root)) queryNode(_root, _queryRect);
			else
			{
				if (_queryRect.isIntersect(_root))
				{
					p_ltX = p_ltX < _root.leftTopX ? _root.leftTopX : p_ltX;
					p_ltY = p_ltY < _root.leftTopY ? _root.leftTopY : p_ltY;
					p_rbX = p_rbX > _root.rightBottomX ? _root.rightBottomX : p_rbX;
					p_rbY = p_rbY > _root.rightBottomY ? _root.rightBottomY : p_rbY;

					_queryRect.set(p_ltX, p_ltY, p_rbX - p_ltX, p_rbY - p_ltY);
					queryNode(_root, _queryRect);
				}
			}

			return _result;
		}

		/**
		 * Makes query from full node.
		 */
		[Inline]
		final private function queryNode(p_node:BBQuadNode, p_rect:BBRect):void
		{
			if (p_node.isInside(p_rect))
			{
				p_node.getBranchBoxes(_result);
			}
			else
			{
				// get boxes
				var box:BBBox = p_node.boxesListHead;
				if (box)
				{
					var len:int = _result.length;
					while (box)
					{
						if (box.isIntersect(p_rect)) _result[len++] = box;
						box = box.next;
					}
				}

				if (!p_node.hasChildrenNodes) return;

				///
				var nCX:Number = p_node.centerX;
				var nCY:Number = p_node.centerY;

				var qLTX:Number = p_rect.leftTopX;
				var qLTY:Number = p_rect.leftTopY;
				var qRBX:Number = p_rect.rightBottomX;
				var qRBY:Number = p_rect.rightBottomY;
				var qWidth:Number = p_rect.width;
				var qHeight:Number = p_rect.height;

				//
				if (qLTX >= nCX) // имеем дело с правой частью нода
				{
					if (qLTY >= nCY) // имеем дело с 4-м квадрантом (правым нижним)
					{
						queryNode(p_node.rightBottomNode, p_rect);
					}
					else if (qRBY <= nCY)  // имеем дело с 2-м квадрантом (правым верхним)
					{
						queryNode(p_node.rightTopNode, p_rect);
					}
					else                 // имеем дело с 2-м и 4-м квадрантами
					{
						queryNode(p_node.rightTopNode, p_rect.set(qLTX, qLTY, qWidth, nCY - qLTY));
						queryNode(p_node.rightBottomNode, p_rect.set(qLTX, nCY, qWidth, qRBY - nCY));
					}
				}
				else if (qRBX <= nCX) // имеем дело с левой частью нода
				{
					if (qLTY >= nCY) // имеем дело с 3-м квадрантом (левым нижним)
					{
						queryNode(p_node.leftBottomNode, p_rect);
					}
					else if (qRBY <= nCY)  // имеем дело с 1-м квадрантом (левым верхним)
					{
						queryNode(p_node.leftTopNode, p_rect);
					}
					else                 // имеем дело с 1-м и 3-м квадрантами
					{
						queryNode(p_node.leftTopNode, p_rect.set(qLTX, qLTY, qWidth, nCY - qLTY));
						queryNode(p_node.leftBottomNode, p_rect.set(qLTX, nCY, qWidth, qRBY - nCY));
					}
				}
				else
				{
					if (qLTY >= nCY) // имеем дело с нижними квадрантами (3 и 4)
					{
						queryNode(p_node.leftBottomNode, p_rect.set(qLTX, qLTY, nCX - qLTX, qHeight));
						queryNode(p_node.rightBottomNode, p_rect.set(nCX, qLTY, qRBX - nCX, qHeight));
					}
					else if (qRBY <= nCY)  // имеем дело с верхними квадрантами (1 и 2)
					{
						queryNode(p_node.leftTopNode, p_rect.set(qLTX, qLTY, nCX - qLTX, qHeight));
						queryNode(p_node.rightTopNode, p_rect.set(nCX, qLTY, qRBX - nCX, qHeight));
					}
					else                // имеем дело со всеми четырьмя квадрантами
					{
						// left-top quadrant
						queryNode(p_node.leftTopNode, p_rect.set(qLTX, qLTY, nCX - qLTX, nCY - qLTY));

						// right-top
						queryNode(p_node.rightTopNode, p_rect.set(nCX, qLTY, qRBX - nCX, nCY - qLTY));

						// left-bottom
						queryNode(p_node.leftBottomNode, p_rect.set(qLTX, nCY, nCX - qLTX, qRBY - nCY));

						// right-bottom
						queryNode(p_node.rightBottomNode, p_rect.set(nCX, nCY, qRBX - nCX, qRBY - nCY));
					}
				}
			}
		}

		/**
		 */
		[Inline]
		final private function getDistance(x1:Number, y1:Number, x2:Number, y2:Number):Number
		{
			var xd:Number = x1 - x2;
			var yd:Number = y1 - y2;

			return xd * xd + yd * yd;
		}

		/**
		 * Root of tree.
		 */
		internal function get root():BBQuadNode
		{
			return _root;
		}

		/**
		 * Returns tree size.
		 */
		public function get size():Number
		{
			return _root.greaterSide;
		}

		/**
		 * Left-top x of quad-tree.
		 */
		public function get x():Number
		{
			return _root.leftTopX;
		}

		/**
		 * Left-top y of quad-tree.
		 */
		public function get y():Number
		{
			return _root.leftTopY;
		}

		/**
		 * Completely dispose the tree.
		 * Impossible to use tree after disposing.
		 */
		public function dispose(p_clearPools:Boolean = true):void
		{
			_root.dispose();
			_root = null;

			if (p_clearPools) clear();
		}

		/**
		 * Clear tree's cache.
		 */
		static public function clear():void
		{
			BBBox.rid();
			BBQuadNode.rid();
		}
	}
}
