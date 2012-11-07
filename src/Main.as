package 
{
	import com.bit101.components.Label;
	import com.bit101.components.NumericStepper;
	import com.bit101.components.PushButton;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Keyboard;
	import nape.geom.GeomPoly;
	import nape.geom.GeomPolyList;
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.phys.BodyType;
	import nape.shape.Circle;
	import nape.shape.Polygon;
	import nape.space.Space;
	import nape.util.BitmapDebug;
	import nape.util.Debug;
	
	/**
	 * ...
	 * @author David Ronai
	 */
	public class Main extends Sprite 
	{
		private var debug:Debug;
		private var space:Space;
		private var lastPoint:Point;
		private var balls:Vector.<Body>;
		private var obstacles:Vector.<Body>;
		private var gravityX:NumericStepper;
		private var gravityY:NumericStepper;
		private var ballRadius:NumericStepper;
		private var ballDensity:NumericStepper;
		
		public function Main():void 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			balls = new Vector.<Body>();
			obstacles = new Vector.<Body>();
			
			var sh:int = stage.stageHeight;
			var sw:int = stage.stageWidth;
			
			var sprite:Sprite = new Sprite();
			sprite.graphics.beginFill(0, 0);
			sprite.graphics.drawRect(0, 0, sw, sh);
			sprite.graphics.endFill();
			sprite.cacheAsBitmap = true;
			addChild(sprite);
			
			debug = new BitmapDebug(sw, sh, 0xEEEEEE, false);
			debug.drawShapeAngleIndicators = false
			addChild(debug.display);
			space = new Space(new Vec2(0, 5));
			
			//border
			var border:Body = new Body(BodyType.STATIC);
			border.shapes.add(new Polygon(Polygon.rect(0,  0, -20, sh)));
			border.shapes.add(new Polygon(Polygon.rect(sw, 0, 20, sh)));
			border.shapes.add(new Polygon(Polygon.rect(0, 0, sw, -20)));
			border.shapes.add(new Polygon(Polygon.rect(0, sh, sw, 20)));
			border.space = space;
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			new Label(this, 300, 10, "Double click = ball // Click to 2 different points = polygon");
			
			new PushButton(this, 115, 10, "undo (backspace)", removeLast);
			new PushButton(this, 10, 35, "remove balls", removeAllBalls);
			new PushButton(this, 10, 10, "remove all (space)", removeAll);
			
			gravityX = new NumericStepper(this, 10, 60, onChange);
			gravityX.value = 0;
			gravityX.width = 70;
			new Label(this, 85, 60, "gravity X");
			gravityY = new NumericStepper(this, 10, 85, onChange);
			gravityY.value = 5;
			gravityY.width = 70;
			new Label(this, 85, 85, "gravity Y");
			ballRadius = new NumericStepper(this, 10, 110, onChange);
			ballRadius.value = 20;
			ballRadius.width = 70;
			new Label(this, 85, 110, "ball radius");
			ballDensity = new NumericStepper(this, 10, 135, onChange);
			ballDensity.value = 10;
			ballDensity.width = 70;
			new Label(this, 85, 135, "ball density");
			sprite.addEventListener(MouseEvent.CLICK, onClick);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		
		private function onKeyDown(e:KeyboardEvent):void 
		{
			switch(e.keyCode) {
				case Keyboard.SPACE: 
					removeAll();
					break;
				case Keyboard.BACKSPACE:
					removeLast();
					break;
				default:
					break;
			}
		}
		
		private function removeLast(e:Event=null):void 
		{
			if ( obstacles.length == 0) return;
			
			var b:Body = obstacles.splice(obstacles.length-1, 1)[0];
			b.space = null;
		}
		
		private function onChange(e:Event):void 
		{
			space.gravity.x = gravityX.value;
			space.gravity.y = gravityY.value;
		}
		
		
		
		public function removeAllBalls(e:Event=null):void {
			var ball:Body;
			for ( var i:int = balls.length-1; i >= 0; i--) {
				ball = balls.splice(i, 1)[0];
				ball.space = null;
			}
		}
		
		public function removeAll(e:Event=null):void {
			var b:Body;
			for ( var i:int = obstacles.length-1; i >= 0; i--) {
				b = obstacles.splice(i, 1)[0];
				b.space = null;
			}
			removeAllBalls();
		}
		
		private function onClick(e:MouseEvent):void 
		{
			if (lastPoint == null) {
				lastPoint = new Point(mouseX, mouseY);
			} else {
				var p:Point = new Point(mouseX, mouseY);
				var geom:GeomPolyList = new GeomPolyList();
				//Square sample
				var dx:int = p.x - lastPoint.x;
				var dy:int = p.y - lastPoint.y;
				
				if ( Math.abs(dx) + Math.abs(dy) < 20) {
					removeAllBalls();
					var ball:Body = new Body();
					ball.position.setxy(mouseX, mouseY);
					var circle:Circle = new Circle(ballRadius.value);
					ball.gravMass = ballDensity.value/10;
					//circle.fluidEnabled = true;
					//circle.fluidProperties.density = circle.material.density = ballDensity.value;
					//circle.fluidProperties.viscosity = ballViscosity;
					//circle.filter.fluidGroup = 2;
					//circle.filter.fluidMask = ~2;
					circle.body = ball;
					ball.space = space;
					
					balls.push(ball);
					lastPoint = null;
					return;
				}
				
				var angle:Number = Math.atan2(dy, dx)+Math.PI/2;
				
				var radius:int = 20;
				geom.add(new GeomPoly(
				Vector.<Vec2>(
				[
					new Vec2(p.x-Math.cos(angle)*radius, p.y-Math.sin(angle)*radius),
					new Vec2(lastPoint.x-Math.cos(angle)*radius, lastPoint.y-Math.sin(angle)*radius),
					new Vec2(lastPoint.x+Math.cos(angle)*radius, lastPoint.y+Math.sin(angle)*radius),
					new Vec2(p.x+Math.cos(angle)*radius, p.y+Math.sin(angle)*radius)	
				])));
				var ramp:Body = new Body(BodyType.STATIC);
				for (var i:int = 0; i < geom.length; i++) {
					var poly:GeomPoly = geom.at(i);
					var polys:GeomPolyList = poly.convex_decomposition();
					for (var j:int = 0; j < polys.length; j++) {
						ramp.shapes.add(new Polygon(polys.at(j)));
					}
				}
				ramp.space = space;
				obstacles.push(ramp);
				
				lastPoint = null;
			}
		}
		
		private function onEnterFrame(e:Event):void 
		{
			space.step(1, 1, 1);
			debug.clear();
			debug.draw(space);
			debug.flush();
		}
		
	}
	
}