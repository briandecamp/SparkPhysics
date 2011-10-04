package com.flexmojo.physics
{
    import Box2D.Common.Math.b2Vec2;
    import Box2D.Dynamics.b2Body;
    import Box2D.Dynamics.b2Fixture;
    import Box2D.Dynamics.b2World;
    
    import com.flexmojo.physics.event.FixtureEvent;
    
    import flash.events.Event;
    import flash.events.MouseEvent;
    
    import mx.events.MoveEvent;
    import mx.events.ResizeEvent;
    
    import spark.components.supportClasses.GroupBase;
    import spark.components.supportClasses.SkinnableComponent;
    import spark.events.ElementExistenceEvent;
    import spark.layouts.BasicLayout;
    import com.flexmojo.physics.adapter.IPhysicsAdapter;
    
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
		private var bodyMap:Object = {};
		
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
			var body:b2Body = bodyMap[pc];
			if(body) {
				world.DestroyBody(body);

				delete bodyMap[pc];
				
				pc.removeEventListener(ResizeEvent.RESIZE, onResize);
				pc.removeEventListener(MoveEvent.MOVE, onMove);
			}
		}
		
		private function affix(pc:SkinnableComponent):void {
			var body:b2Body = bodyMap[pc];
			if(!body) {
				var physicsAdapterClass:Class = pc.getStyle("physicsAdapterClass");
				if(physicsAdapterClass) {
					var adapter:IPhysicsAdapter = new physicsAdapterClass();
					body = adapter.createBody(pc, world);
					bodyMap[pc] = body;
					
					// If we are working with bonefide PhysicalComponent, 
					// set the physicalBody. PhysicalCompnent should probably be an interface here.
					if(pc is PhysicalComponent) PhysicalComponent(pc).physicalBody = body;

					// Redraw the DebugSkin if necessary
					if(pc.skin is PhysicalComponentSkin) {
						PhysicalComponentSkin(pc.skin).drawPhysics(body);
					}
					
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
			var body:b2Body = bodyMap[pc];
			if(body && imperturbable(pc)) {
				detach(pc);
				affix(pc);
			}
		}
		
		// The fixtures may need to be updated
		protected function onResize(event:Event):void
		{
			var pc:SkinnableComponent = event.target as SkinnableComponent;
			var body:b2Body = bodyMap[pc];
			if(body) {
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
            if(!_world) return;
			
            for (var nextBody:b2Body = world.GetBodyList(); nextBody; nextBody = nextBody.GetNext()) {
                var pc:SkinnableComponent = nextBody.GetUserData() as SkinnableComponent;
                if(!pc) continue;
				
				if(!imperturbable(pc)) {
					pc.x = Math.round(nextBody.GetPosition().x * PPM);
					pc.y = Math.round(nextBody.GetPosition().y * PPM);
					pc.rotation = nextBody.GetAngle() * (180/Math.PI);
				}
            }
        }
    }
}