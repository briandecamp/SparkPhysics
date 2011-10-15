/*
* Copyright (c) 2011 Brian DeCamp http://flexmojo.com
*
* This software is provided 'as-is', without any express or implied
* warranty.  In no event will the authors be held liable for any damages
* arising from the use of this software.
* Permission is granted to anyone to use this software for any purpose,
* including commercial applications, and to alter it and redistribute it
* freely, subject to the following restrictions:
* 1. The origin of this software must not be misrepresented; you must not
* claim that you wrote the original software. If you use this software
* in a product, an acknowledgment in the product documentation would be
* appreciated but is not required.
* 2. Altered source versions must be plainly marked as such, and must not be
* misrepresented as being the original software.
* 3. This notice may not be removed or altered from any source distribution.
*/
package com.flexmojo.physics.joint
{
	import Box2D.Common.Math.b2Vec2;
	import Box2D.Dynamics.Joints.b2MouseJoint;
	import Box2D.Dynamics.Joints.b2MouseJointDef;
	import Box2D.Dynamics.b2Fixture;
	import Box2D.Dynamics.b2World;
	
	import com.flexmojo.physics.PhysicsLayout;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	
	import spark.components.SkinnableContainer;

	[Event(name="jointDestroyed", type="flash.events.Event")]
	public class MouseJointFactory extends EventDispatcher
	{
		public var maxAcceleration:Number = 980;
		public var target:SkinnableContainer;

		private var _physicalJoint:b2MouseJoint = null;
		private var _graphicJoint:Joint = null;

		public function createMouseJoint(fixture:b2Fixture):void {
			destroyJoint();
			
			var mouseJointDef:b2MouseJointDef = new b2MouseJointDef();
			mouseJointDef.bodyA = world.GetGroundBody();
			mouseJointDef.bodyB = fixture.GetBody();
			mouseJointDef.target.Set(target.mouseX/PhysicsLayout.PPM, target.mouseY/PhysicsLayout.PPM);
			mouseJointDef.maxForce = maxAcceleration * fixture.GetBody().GetMass();
			
			_physicalJoint = world.CreateJoint(mouseJointDef) as b2MouseJoint;
			fixture.GetBody().SetAwake(true);
			
			_graphicJoint = new Joint();
			target.addElementAt(_graphicJoint, 0);
			
			// Listen for the release
			target.parentApplication.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
			(target.layout as PhysicsLayout).addEventListener(PhysicsLayout.AFTER_STEP, afterStepHandler);
		}
		
		private function get world():b2World {
			return (target.layout as PhysicsLayout).world;
		}
		
		private function afterStepHandler(event:Event):void {
			if (_physicalJoint) {
				var p2:b2Vec2 = new b2Vec2(target.mouseX/PhysicsLayout.PPM, target.mouseY/PhysicsLayout.PPM);
				_physicalJoint.SetTarget(p2);
			}
			if(_graphicJoint && _physicalJoint) {
				_graphicJoint.x = _physicalJoint.GetAnchorA().x * PhysicsLayout.PPM;
				_graphicJoint.y = _physicalJoint.GetAnchorA().y * PhysicsLayout.PPM;
				_graphicJoint.xTo = (_physicalJoint.GetAnchorB().x - _physicalJoint.GetAnchorA().x) * PhysicsLayout.PPM;
				_graphicJoint.yTo = (_physicalJoint.GetAnchorB().y -_physicalJoint.GetAnchorA().y) * PhysicsLayout.PPM;
			}
		}
		
		private function destroyJoint():void {
			var destroyedJoint:Boolean = false;
			if (_physicalJoint != null && world != null) {
				world.DestroyJoint(_physicalJoint);
				_physicalJoint = null;
				target.parentApplication.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
				(target.layout as PhysicsLayout).removeEventListener(PhysicsLayout.AFTER_STEP, afterStepHandler);
				destroyedJoint = true;
			}
			if(_graphicJoint != null && target != null) {
				target.removeElement(_graphicJoint);
				_graphicJoint = null;
			}
			if(destroyedJoint) {
				dispatchEvent(new Event('jointDestroyed'));
			}
		}
		
		private function mouseUpHandler(mouseEvent:MouseEvent):void {
			destroyJoint();
		}
	}
}