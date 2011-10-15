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
package com.flexmojo.physics.adapter
{
	import Box2D.Collision.Shapes.b2PolygonShape;
	import Box2D.Collision.Shapes.b2Shape;
	import Box2D.Common.Math.b2Vec2;
	import Box2D.Dynamics.b2Body;
	import Box2D.Dynamics.b2BodyDef;
	import Box2D.Dynamics.b2FixtureDef;
	import Box2D.Dynamics.b2World;
	
	import com.flexmojo.physics.PhysicsLayout;
	
	import mx.collections.ArrayCollection;
	
	import spark.components.supportClasses.SkinnableComponent;
	
	public class DefaultPhysicsAdapter implements IPhysicsAdapter
	{
		/**
		 * Subclasses probably want to override this method. This is the trickiest part of
		 * converting a flex component into a physical fixture.
		 * 
		 */
		protected function createShapes(comp:SkinnableComponent):Vector.<b2Shape> {
			var shapes:Vector.<b2Shape> = new Vector.<b2Shape>(1, true);
			
			// Default to a rectangle
			var box:b2PolygonShape = new b2PolygonShape();
			var halfWidth:Number = comp.width/(2*PhysicsLayout.PPM);
			var halfHeight:Number = comp.height/(2*PhysicsLayout.PPM);
			box.SetAsOrientedBox(halfWidth, halfHeight, new b2Vec2(halfWidth, halfHeight));
			shapes[0] = box;

			return shapes;
		}

		protected function createFixDefs(comp:SkinnableComponent):Vector.<b2FixtureDef> {
			var shapes:Vector.<b2Shape> = createShapes(comp);
			var fixDefs:Vector.<b2FixtureDef> = new Vector.<b2FixtureDef>(shapes.length, true);
			var i:int = 0;
			for each (var shape:b2Shape in shapes) {
				var fixtureDef:b2FixtureDef = new b2FixtureDef();
				fixtureDef.shape = shape;
				if(comp.getStyle("density")) fixtureDef.density = comp.getStyle("density");
				if(comp.getStyle("friction")) fixtureDef.friction = comp.getStyle("friction");
				if(comp.getStyle("restitution")) fixtureDef.restitution = comp.getStyle("restitution");
				fixDefs[i++] = fixtureDef;
			}
			return fixDefs;
		}
		
		protected function createBodyDef(comp:SkinnableComponent):b2BodyDef {
			var bodyDef:b2BodyDef = new b2BodyDef();
			var bodyType:* = comp.getStyle("bodyType");
			if(bodyType == "dynamic") {
				bodyDef.type = b2Body.b2_dynamicBody;
			} else if(bodyType == "kinematic") {
				bodyDef.type = b2Body.b2_kinematicBody;
			} else if(bodyType == "static" || bodyType == undefined) {
				bodyDef.type = b2Body.b2_staticBody;
			} else {
				throw new Error("unknown bodyType: " + bodyType);
			}
			bodyDef.position.Set(comp.x/PhysicsLayout.PPM, comp.y/PhysicsLayout.PPM);
			bodyDef.angle = comp.rotation * Math.PI / 180;
			bodyDef.userData = comp;
			if(comp.getStyle("angularDamping")) bodyDef.angularDamping = comp.getStyle("angularDamping");
			if(comp.getStyle("linearDamping")) bodyDef.linearDamping = comp.getStyle("linearDamping");
			if(comp.getStyle("inertiaScale")) bodyDef.inertiaScale = comp.getStyle("inertiaScale");
			if(comp.getStyle("allowSleep") == false) bodyDef.allowSleep = false;
			if(comp.getStyle("bullet") == true) bodyDef.bullet = true;
			if(comp.getStyle("fixedRotation") == true) bodyDef.fixedRotation = true;
			return bodyDef;
		}

		public function createBody(comp:SkinnableComponent, world:b2World):b2Body {
			var bodyDef:b2BodyDef = createBodyDef(comp);
			var body:b2Body = world.CreateBody(bodyDef);
			var fixDefs:Vector.<b2FixtureDef> = createFixDefs(comp);
			for each (var fixDef:b2FixtureDef in fixDefs) {
				body.CreateFixture(fixDef);
			}
			return body;
		}
		
	}
}