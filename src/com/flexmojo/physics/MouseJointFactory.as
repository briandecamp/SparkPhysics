package com.flexmojo.physics
{
	import Box2D.Collision.b2AABB;
	import Box2D.Common.Math.b2Vec2;
	import Box2D.Dynamics.Joints.b2DistanceJoint;
	import Box2D.Dynamics.Joints.b2DistanceJointDef;
	import Box2D.Dynamics.Joints.b2Joint;
	import Box2D.Dynamics.Joints.b2JointEdge;
	import Box2D.Dynamics.Joints.b2MouseJoint;
	import Box2D.Dynamics.Joints.b2MouseJointDef;
	import Box2D.Dynamics.b2Body;
	import Box2D.Dynamics.b2Fixture;
	import Box2D.Dynamics.b2World;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.events.FlexEvent;
	
	import spark.components.Group;
	import spark.components.SkinnableContainer;

	[Event(name="jointDestroyed", type="flash.events.Event")]
	public class MouseJointFactory
	{
		public var world:b2World;
		public var maxAcceleration:Number = 980;
		private var _mouseJoint:b2MouseJoint = null;
		private var _graphicJoint:Joint = null;
		private var _target:SkinnableContainer;

		[Bindable]
		public function get target():SkinnableContainer {
			return _target;
		}
		
		public function set target(t:SkinnableContainer):void {
			if(_target) {
				_target.contentGroup.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
			}
			_target = t;
			if(_target) {
				// We can only start listening after initialization
				if(_target.initialized) {
					_target.contentGroup.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
				} else {
					_target.addEventListener(FlexEvent.INITIALIZE, onTargetInitialization);
				}
			}
		}
		
		private function onTargetInitialization(event:Event):void {
			_target.contentGroup.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
		}
		
		public function updateJoint():void {
			if (_mouseJoint) {
				var p2:b2Vec2 = new b2Vec2(target.mouseX/PhysicsLayout.PPM, target.mouseY/PhysicsLayout.PPM);
				_mouseJoint.SetTarget(p2);
			}
			if(_graphicJoint && _mouseJoint) {
				_graphicJoint.x = _mouseJoint.GetAnchorA().x * PhysicsLayout.PPM;
				_graphicJoint.y = _mouseJoint.GetAnchorA().y * PhysicsLayout.PPM;
				_graphicJoint.xTo = (_mouseJoint.GetAnchorB().x - _mouseJoint.GetAnchorA().x) * PhysicsLayout.PPM;
				_graphicJoint.yTo = (_mouseJoint.GetAnchorB().y -_mouseJoint.GetAnchorA().y) * PhysicsLayout.PPM;
			}
		}
		
		public function createMouseJoint(fixture:b2Fixture):void {
			var mouseJointDef:b2MouseJointDef = new b2MouseJointDef();
			mouseJointDef.bodyA = world.GetGroundBody();
			mouseJointDef.bodyB = fixture.GetBody();
			mouseJointDef.target.Set(target.mouseX/PhysicsLayout.PPM, target.mouseY/PhysicsLayout.PPM);
			mouseJointDef.maxForce = maxAcceleration * fixture.GetBody().GetMass();
			
			_mouseJoint = world.CreateJoint(mouseJointDef) as b2MouseJoint;
			fixture.GetBody().SetAwake(true);
			
			_graphicJoint = new Joint();
			target.addElementAt(_graphicJoint, 0);
		}
		
		private function mouseUpHandler(mouseEvent:MouseEvent):void {
			if(_graphicJoint && target) {
				target.removeElement(_graphicJoint);
				_graphicJoint = null;
			}
			if (_mouseJoint && world) {
				world.DestroyJoint(_mouseJoint);
				_mouseJoint = null;
				
				dispatchEvent(new Event('jointDestroyed'));
			}
		}
	}
}