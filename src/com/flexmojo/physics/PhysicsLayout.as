package com.flexmojo.physics
{
    import Box2D.Collision.Shapes.b2CircleShape;
    import Box2D.Collision.Shapes.b2PolygonShape;
    import Box2D.Collision.Shapes.b2Shape;
    import Box2D.Common.Math.b2Math;
    import Box2D.Common.Math.b2Vec2;
    import Box2D.Dynamics.Joints.b2DistanceJoint;
    import Box2D.Dynamics.Joints.b2Joint;
    import Box2D.Dynamics.Joints.b2MouseJoint;
    import Box2D.Dynamics.Joints.b2PulleyJoint;
    import Box2D.Dynamics.b2Body;
    import Box2D.Dynamics.b2Fixture;
    import Box2D.Dynamics.b2World;
    
    import com.flexmojo.physics.event.FixtureEvent;
    
    import flash.display.Graphics;
    import flash.events.Event;
    import flash.events.MouseEvent;
    
    import mx.collections.ArrayCollection;
    import mx.events.MoveEvent;
    import mx.events.ResizeEvent;
    
    import spark.components.supportClasses.GroupBase;
    import spark.components.supportClasses.SkinnableComponent;
    import spark.events.ElementExistenceEvent;
    import spark.layouts.BasicLayout;
    
	[Event(name="beforeStep", type="flash.events.Event")]
	[Event(name="afterStep", type="flash.events.Event")]
	[Event(name="fixtureSelected", type="com.flexmojo.physics.event.FixtureEvent")]
    public class PhysicsLayout extends BasicLayout
    {
		public static const VELOCITY_ITERATIONS:int = 10;
		public static const POSITION_ITERATIONS:int = 10;
		public static const TIMESTEP:Number = 1/60;
		public static const PPM:Number = 100; // pixels per meter
		public static const BEFORE_STEP:String = "beforeStep";
		public static const AFTER_STEP:String = "afterStep";

		private var _world:b2World;
		
		[Bindable(event="worldChanged")]
		public function get world():b2World {
			return _world;
		}

		// Map of a component to an ArrayCollection<b2Fixture> for the component
		private var fixtureSets:Object = {};
		
		private var _acceleration:Number = 9.8;
		
		public function set acceleration(acc:Number):void {
			_acceleration = acc;
			if(_world) {
				var gravity:b2Vec2 = new b2Vec2(0, _acceleration);
				_world.SetGravity(gravity);
			}
		}
		
		[Bindable]
		public function get acceleration():Number {
			return _acceleration;
		}
		
		/**
		 * Accessor that starts/stop the physics world.
		 * Manage all possible race/startup conditions for setting target and physicsEnabled
		 */
		private var _physicsEnabled:Boolean = false;
		
		[Bindable]
		public function get physicsEnabled():Boolean {
			return _physicsEnabled;
		}
		
		public function set physicsEnabled(value:Boolean):void {
			_physicsEnabled = value;
		}
		
		public function destroyWorld():void {
			if(_world) {
				for(var body:b2Body = _world.GetBodyList(); body; body = body.GetNext()) {
					var sc:SkinnableComponent = body.GetUserData() as SkinnableComponent;
					if(sc) detach(sc);
				}
				_world = null;
				dispatchEvent(new Event("worldChanged"));
			}
		}
		
		override public function set target(value:GroupBase):void {
			if(target) {
				target.removeEventListener("elementAdd", onElementAdd);
				target.removeEventListener("elementRemove", onElementRemove);
				target.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
				target.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
				destroyWorld();
			}
			super.target = value;
			if(target) {
				target.addEventListener("elementAdd", onElementAdd);
				target.addEventListener("elementRemove", onElementRemove);
				target.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
				target.addEventListener(Event.ENTER_FRAME, onEnterFrame);
				
				if(!world) {
					initWorld();
				}
			}
		}
		
		private function onMouseDown(event:MouseEvent):void {
			if (world) {
				world.QueryPoint(onMouseHit, new b2Vec2(target.mouseX/PPM, target.mouseY/PPM));
			}
		}
		
		private function onMouseHit(fixture:b2Fixture):Boolean {
			var event:FixtureEvent = new FixtureEvent(FixtureEvent.FIXTURE_SELECTED);
			event.fixture = fixture;
			dispatchEvent(event);
			return false;
		}        

		private function imperturbable(pc:SkinnableComponent):Boolean {
			return pc.getStyle("density") == 0;
		}
		
		private function detach(pc:SkinnableComponent):void {
			var fixtures:ArrayCollection = fixtureSets[pc];
			if(fixtures) {
				for each (var fixture:b2Fixture in fixtures) {
					world.DestroyBody(fixture.GetBody());
				}

				delete fixtureSets[pc];
				
				pc.removeEventListener(ResizeEvent.RESIZE, onResize);
				pc.removeEventListener(MoveEvent.MOVE, onMove);
			}
		}
		
		private function affix(pc:SkinnableComponent):void {
			var fixtures:ArrayCollection = fixtureSets[pc];
			if(!fixtures) {
				var fixtureClass:Class = pc.getStyle("fixtureAdapterClass");
				if(fixtureClass) {
					var adapter:IFixtureAdapter = new fixtureClass();
					fixtures = adapter.createFixtures(pc, world);
					fixtureSets[pc] = fixtures;
					
					// If we are working with bonefide PhysicalComponent, 
					// set the fixtures. PhysicalCompnent should probably be an interface here.
					if(pc is PhysicalComponent) PhysicalComponent(pc).fixtures = fixtures.toArray();
					
					pc.addEventListener(ResizeEvent.RESIZE, onResize);
					pc.addEventListener(MoveEvent.MOVE, onMove);
				}
			}
		}
		
		/*
		 * If an imperturbable component moves, it must have
		 * been due to the layout. Resize the fixtures.
		 * Ignore move events for floating components.
		 */
		protected function onMove(event:Event):void
		{
			var pc:SkinnableComponent = event.target as SkinnableComponent;
			var fix:ArrayCollection = fixtureSets[pc];
			if(fix && imperturbable(pc)) {
				detach(pc);
				affix(pc);
			}
		}
		
		// The fixtures may need to be updated
		protected function onResize(event:Event):void
		{
			var pc:SkinnableComponent = event.target as SkinnableComponent;
			var fix:ArrayCollection = fixtureSets[pc];
			if(fix) {
				detach(pc);
				affix(pc);
			}
		}
		
		private function onElementAdd(event:ElementExistenceEvent):void {
			var pc:SkinnableComponent = event.element as SkinnableComponent;
			if(pc && _world) {
				affix(pc);
			}
		}
		
		private function onElementRemove(event:ElementExistenceEvent):void {
			var pc:SkinnableComponent = event.element as SkinnableComponent;
			if(pc && _world) {
				detach(pc);
			}
		}
		
        /**
         * enterFrame_handler
         * 
         * Applies physics to the actual container children for each frame.
         */
        private function onEnterFrame(event:Event):void {
			if(world && physicsEnabled) {
				dispatchEvent(new Event("beforeStep"));
				world.Step(TIMESTEP, VELOCITY_ITERATIONS, POSITION_ITERATIONS);
				world.ClearForces();
				target.invalidateDisplayList();
				dispatchEvent(new Event("afterStep"));
			}
		}

		private function initWorld():void {
			var gravity:b2Vec2 = new b2Vec2(0, acceleration);

			// allow bodies to sleep in the world
			var doSleep:Boolean = true;
			
			_world = new b2World(gravity, doSleep);
			dispatchEvent(new Event("worldChanged"));
			
			// Load the current items in the target
			for(var i:int = 0; i < target.numElements; i++) {
				var pc:SkinnableComponent = target.getElementAt(i) as SkinnableComponent;
				if(!pc) continue;
				
				affix(pc);
			}
		}

		override public function updateDisplayList(width:Number, height:Number):void {
			super.updateDisplayList(width, height);
            target.graphics.clear();
            if(!_world) return;
			
            // DEBUG
            for (var nextJoint:b2Joint = world.GetJointList(); nextJoint; nextJoint = nextJoint.GetNext()) {
//                drawJoint(nextJoint);
            }
            for (var nextBody:b2Body = world.GetBodyList(); nextBody; nextBody = nextBody.GetNext()) {
                // DEBUG
//                drawShapes(nextBody);
                var pc:SkinnableComponent = nextBody.GetUserData() as SkinnableComponent;
                if(!pc) continue;
				
				if(!imperturbable(pc)) {
					pc.x = Math.round(nextBody.GetPosition().x * PPM);
					pc.y = Math.round(nextBody.GetPosition().y * PPM);
					pc.rotation = nextBody.GetAngle() * (180/Math.PI);
				}
            }
        }
        
		private function drawJoint(joint:b2Joint):void {
			var body1:b2Body = joint.GetBodyA();
			var body2:b2Body = joint.GetBodyB();
			
			var body1Position:b2Vec2 = body1.GetPosition();
			var body2Position:b2Vec2 = body2.GetPosition();
			
			var body1Anchor:b2Vec2 = joint.GetAnchorA();
			var body2Anchor:b2Vec2 = joint.GetAnchorB();
			
			var containerGraphics:Graphics = target.graphics;
			
			containerGraphics.lineStyle(1, 0x501DFF, 1);
			
			if(joint is b2DistanceJoint || joint is b2MouseJoint) {
				containerGraphics.moveTo(body1Anchor.x * PPM, body1Anchor.y * PPM);
				containerGraphics.lineTo(body2Anchor.x * PPM, body2Anchor.y * PPM);
			} else if(joint is b2PulleyJoint) {
				var pulley:b2PulleyJoint = joint as b2PulleyJoint;
				var s1:b2Vec2 = pulley.GetGroundAnchorA();
				var s2:b2Vec2 = pulley.GetGroundAnchorB();
				containerGraphics.moveTo(s1.x * PPM, s1.y * PPM);
				containerGraphics.lineTo(body1Anchor.x * PPM, body1Anchor.y * PPM);
				containerGraphics.moveTo(s2.x * PPM, s2.y * PPM);
				containerGraphics.lineTo(body2Anchor.x * PPM, body2Anchor.y * PPM);
			} else {
				if (body1 == world.GetGroundBody()) {
					containerGraphics.moveTo(body1Anchor.x * PPM, body1Anchor.y * PPM);
					containerGraphics.lineTo(body2Position.x * PPM, body2Position.y * PPM);
				} else if (body2 == world.GetGroundBody()) {
					containerGraphics.moveTo(body1Anchor.x * PPM, body1Anchor.y * PPM);
					containerGraphics.lineTo(body1Position.x * PPM, body1Position.y * PPM);
				} else {
					containerGraphics.moveTo(body1Position.x * PPM, body1Position.y * PPM);
					containerGraphics.lineTo(body1Anchor.x * PPM, body1Anchor.y * PPM);
					containerGraphics.lineTo(body2Position.x * PPM, body2Position.y * PPM);
					containerGraphics.lineTo(body2Anchor.x * PPM, body2Anchor.y * PPM);
				}
			}
		}
        
		/**
		 * DEBUG
 		 */
        private function drawShapes(body:b2Body):void {
            var v:b2Vec2 = null;
            var containerGraphics:Graphics = target.graphics;
            containerGraphics.lineStyle(1);
			var fixture:b2Fixture = body.GetFixtureList();
			while(fixture) {
				var shape:b2Shape = fixture.GetShape();
				if(shape is b2CircleShape) {
					var circleShape:b2CircleShape = shape as b2CircleShape;
					
					var pos:b2Vec2 = body.GetPosition();
					v = b2Math.AddVV(pos, circleShape.GetLocalPosition());
					var radius:Number = circleShape.GetRadius();
					containerGraphics.drawCircle(v.x * PPM, v.y * PPM, radius * PPM);
					
					var fromX:int = v.x * PPM;
					var fromY:int = v.y * PPM;
					var toX:int = (v.x-radius)*PPM;
					var toY:int = (v.y-radius)*PPM;
					trace('draw ' + fromX + ':' + fromY + ' to ' + toX + ':' + toY);
					containerGraphics.moveTo(v.x*PPM, v.y*PPM);
					containerGraphics.lineTo((v.x-radius)*PPM, (v.y-radius)*PPM);
				} else if(shape is b2PolygonShape) {
					//var poly:b2PolyShape = shape as b2PolyShape;
					var polyShape:b2PolygonShape = shape as b2PolygonShape;
					var startVertex:b2Vec2 = null;
					for each (var vertex:b2Vec2 in polyShape.GetVertices()) {
						if(startVertex) {
							containerGraphics.lineTo(vertex.x * PPM, vertex.y * PPM);
						} else {
							containerGraphics.moveTo(vertex.x * PPM, vertex.y * PPM);
						}
					}
					// close the loop
					if(startVertex) containerGraphics.lineTo(startVertex.x * PPM, startVertex.y * PPM);
						
					/*
					var tV:b2Vec2 = b2Math.AddVV(body.GetPosition(),
					b2Math.b2MulMV(body.GetXForm().R, polyShape.GetVertices()[0]));
					
					containerGraphics.moveTo(tV.x * PPM, tV.y * PPM);
					
					for (var j:int = 0; j < polyShape.GetVertexCount(); ++j) {
					v = b2Math.AddVV(body.GetPosition(),
					b2Math.b2MulMV(body.GetXForm().R, polyShape.GetVertices()[j]));
					containerGraphics.lineTo(v.x * PPM, v.y * PPM);
					}
					containerGraphics.lineTo(tV.x * PPM, tV.y * PPM);
					v = polyShape.GetVertices()[0];
					pos = body.GetPosition();
					containerGraphics.moveTo((pos.x + v.x) * PPM, (pos.y + v.y) * PPM);
					for (var j:int = 1; j < polyShape.GetVertexCount(); ++j) {
					v = polyShape.GetVertices()[j];
					containerGraphics.lineTo((pos.x + v.x) * PPM, (pos.y + v.y) * PPM);
					}
					*/
				}
				fixture = fixture.GetNext();
			}
        }
    }
}