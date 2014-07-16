package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;

	import quadtree.BBBox;
	import quadtree.BBQuadTree;
	import quadtree.BBQuadTreeDebugDraw;

	/**
	 * ...
	 * @author VirtualMaestro
	 */
//	[SWF(width="1024", height="768", frameRate="60")]
	[SWF(width="1280", height="800", frameRate="60")]
	public class QuadTreeTest extends Sprite
	{
		private var _tree:BBQuadTree;
		private var _debug:BBQuadTreeDebugDraw;

		//
		private var _treeSize:int;
		private var _treeStartX:Number;
		private var _treeStartY:Number;

		private var _treeMaxDepth:int;

		//
		private var _hero:BBBox;

		//
		private var _boxes:Vector.<BBBox>;
		private var _minSpeed:int;
		private var _maxSpeed:int;
		private var _minBoxSize:int;
		private var _maxBoxSize:int;
		private var _objectsNum:int;
		private var _fromX:Number;
		private var _toX:Number;
		private var _fromY:Number;
		private var _toY:Number;
		private var _viewPortWidth:Number;
		private var _viewPortHeight:Number;
		private var _mouseX:Number = 0;
		private var _mouseY:Number = 0;

		private var _isViewPort:Boolean = true;

		public var isDrawTest:Boolean = true;
		public var isMoveBoxes:Boolean = true;
		public var isViewportMove:Boolean = true;

		/**
		 */
		public function QuadTreeTest():void
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}

		/**
		 */
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point

			// set params
			_treeSize = 800;
			_treeStartX = -_treeSize*0.5 + stage.stageWidth*0.5;
			_treeStartY = -_treeSize*0.5 + stage.stageHeight*0.5;
			_minSpeed = 1;
			_maxSpeed = 10;
			_minBoxSize = 2;
			_maxBoxSize = 50;
			_objectsNum = 50;
			_fromX = _treeStartX;
			_toX = _treeStartX + _treeSize;
			_fromY = _treeStartY;
			_toY = _treeStartY + _treeSize;
			_viewPortWidth = 400;
			_viewPortHeight = 400;
			_treeMaxDepth = 10;


			//
			_tree = new BBQuadTree(_treeSize, _treeStartX, _treeStartY);
			_tree.maxDepth = _treeMaxDepth;
			_tree.autoExpanding = false;

			_debug = new BBQuadTreeDebugDraw(_tree, stage.stageWidth, stage.stageHeight);
			addChild(_debug);

			addChild(new Stats());
			drawDepth();

			//
			initStat();

			// init hero
			_hero = _tree.add(10, 10, _treeStartX + 100, _treeStartY + 100);

			//
//			stressTest(isMoveBoxes);
			viewPortTest();

			//
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyboardHandler);
			//stage.addEventListener(MouseEvent.CLICK, mouseHandler);

			if (isViewportMove)
			{
				stage.addEventListener(MouseEvent.MOUSE_MOVE, function (event:MouseEvent):void
				{
					_mouseX = event.stageX;
					_mouseY = event.stageY;
				});
			}
		}

		/**
		 */
		private function viewPortTest():void
		{
			_debug.enable = true;
			stressTest(isMoveBoxes);
			stage.addEventListener(Event.ENTER_FRAME, handleBoxesFromViewPort);
		}

		//
		private var _viewportObjects:int = 0;

		/**
		 */
		private function handleBoxesFromViewPort(event:Event):void
		{
			if (_isViewPort)
			{
				var ltX:Number = _mouseX - _viewPortWidth * 0.5;
				var ltY:Number = _mouseY - _viewPortHeight * 0.5;
				var rbX:Number = _mouseX + _viewPortWidth * 0.5;
				var rbY:Number = _mouseY + _viewPortHeight * 0.5;

				var result:Vector.<BBBox>;

				for (var j:int = 0; j < 5; j++)
				{
					result = _tree.get(ltX, ltY, rbX, rbY);
				}


				var len:int = result.length;
				_viewportObjects = len;

				if (isDrawTest)
				{
					if (!_debug.enable)
					{
						_debug.clear();

						var box:BBBox;
						for (var i:int = 0; i < len; i++)
						{
							box = result[i];
							_debug.drawBox(box);
						}
					}

					_debug.drawRect(ltX, ltY, rbX, rbY);
				}
			}
		}

		/**
		 */
		private function stressTest(p_moveBoxes:Boolean = true):void
		{
			addBoxes();
			if (p_moveBoxes) stage.addEventListener(Event.ENTER_FRAME, moveBoxes);
		}

		/**
		 */
		private function addBoxes():void
		{
			_boxes = new Vector.<BBBox>;

			// adds objects
			for (var i:int = 0; i < _objectsNum; i++)
			{
				_boxes[i] = addRandomBox();
			}
		}

		/**
		 */
		private function moveBoxes(event:Event):void
		{
			var len:int = _boxes.length;
			var box:BBBox;
			var speed:Number;
			for (var i:int = 0; i < len; i++)
			{
				box = _boxes[i];
				speed = Number(box.userData);
				if ((box.x + box.widthBox * 0.5 + speed) < (_toX)) box.shiftPosition(speed, 0);
				else box.setPosition(_fromX + box.widthBox * 0.5, box.y);
			}

			updateInfo(_debug.enable, _debug.isWire, _boxes.length, _tree.size);
		}

		/**
		 */
		private function mouseHandler(event:MouseEvent):void
		{
			addBox(event.stageX, event.stageY);
		}

		/**
		 */
		private function keyboardHandler(event:KeyboardEvent):void
		{
			var shift:Number = 5;
			switch (event.keyCode)
			{
				case Keyboard.UP:
				{
					_hero.shiftPosition(0, -shift);
					break;
				}

				case Keyboard.DOWN:
				{
					_hero.shiftPosition(0, shift);
					break;
				}

				case Keyboard.LEFT:
				{
					_hero.shiftPosition(-shift, 0);
					break;
				}

				case Keyboard.RIGHT:
				{
					_hero.shiftPosition(shift, 0);
					break;
				}

				case Keyboard.W:
				{
					_debug.isWire = !_debug.isWire;
					break;
				}

				case Keyboard.V:
				{
					_isViewPort = !_isViewPort;
					_debug.clear();

					break;
				}

				case Keyboard.A:
				{
					for (var i:int = 0; i < 50; i++)
					{
						_boxes.push(addRandomBox());
					}

					break;
				}

				case Keyboard.S:
				{
					var newNum:int;
					if (_boxes.length <= 50) newNum = 0;
					else newNum = _boxes.length - 50;

					i = _boxes.length - 1;
					while (i > newNum - 1)
					{
						_boxes[i].dispose();
						i--;
					}

					_boxes.length = newNum;

					break;
				}

				case Keyboard.D:
				{
					_debug.enable = !_debug.enable;
					break;
				}
			}
		}

		/**
		 */
		private function addBox(p_x:Number, p_y:Number):void
		{
			_tree.add(20, 20, p_x, p_y);
		}

		/**
		 */
		private function addRandomBox():BBBox
		{
			var boxWidth:Number = randomRange(_minBoxSize, _maxBoxSize);
			var boxHeight:Number = randomRange(_minBoxSize, _maxBoxSize);

			var boxX:Number = randomRange(_fromX, _toX);
			var boxY:Number = randomRange(_fromY, _toY);

			if (boxX - boxWidth / 2 < _fromX) boxX += boxWidth / 2 + 1;
			else if (boxX + boxWidth / 2 > _toX) boxX -= boxWidth / 2 + 1;

			if (boxY - boxHeight / 2 < _fromY) boxY += boxHeight / 2 + 1;
			else if (boxY + boxHeight / 2 > _toY) boxY -= boxHeight / 2 + 1;

			var box:BBBox = _tree.add(boxWidth, boxHeight, boxX, boxY);
			box.userData = randomRange(_minSpeed, _maxSpeed);
			box.disposeCallback = disposeCallback;

			return box;
		}

		/**
		 */
		private function disposeCallback(p_box:BBBox):void
		{
			trace("removed box with speed: " + p_box.userData);
		}

		/**
		 */
		private function randomRange(minNum:Number, maxNum:Number):Number
		{
			return (Math.floor(Math.random() * (maxNum - minNum + 1)) + minNum);
		}

		//
		private var _statInfo:TextField;

		/**
		 */
		private function initStat():void
		{
			_statInfo = getTextField(12);
			addChild(_statInfo);
			_statInfo.x = 0;
			_statInfo.y = 100;
		}

		/**
		 */
		private function updateInfo(p_debugDraw:Boolean, p_wireDraw:Boolean, p_numObjects:int, p_treeSize:int):void
		{
			var info:String =
							"Debug draw: " + p_debugDraw + " (D)\n" +
							"ViewPort: " + _isViewPort + " (V)\n" +
							"Wire draw: " + p_wireDraw + " (W)\n" +
							"Num obj-s : " + p_numObjects + " (A/S)\n" +
							"Tree size : " + p_treeSize + "\n" +
							"Objects in VP: " + _viewportObjects;

			_statInfo.text = info;
		}

		/**
		 */
		private function getTextField(p_fontSize:int = 12):TextField
		{
			var textField:TextField = new TextField();
			var tf:TextFormat = textField.defaultTextFormat;
			tf.size = p_fontSize;

			textField.multiline = true;
			textField.wordWrap = true;
			textField.autoSize = TextFieldAutoSize.CENTER;

			return textField;
		}

		/**
		 */
		private function drawDepth():void
		{
			var colors:Array = _debug.colors;
			var num:int = colors.length;
			var startY:Number = 250;
			var container:Sprite = new Sprite();
			addChild(container);
			container.x = 0;
			container.y = startY;
			startY = 20;

			var label:TextField = getTextField();
			label.text = "Depth colors:";
			container.addChild(label);

			for (var i:int = 0; i < num; i++)
			{
				container.graphics.beginFill(colors[i]);
				container.graphics.drawRect(2, startY, 60, 20);
				container.graphics.endFill();

				startY += 21;
			}
		}
	}
}