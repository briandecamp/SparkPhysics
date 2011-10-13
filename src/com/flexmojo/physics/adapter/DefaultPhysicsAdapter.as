package com.flexmojo.physics.adapter
{
	import Box2D.Collision.Shapes.b2PolygonShape;
	import Box2D.Collision.Shapes.b2Shape;
	import Box2D.Common.Math.b2Vec2;
	import Box2D.Dynamics.b2Body;
	import Box2D.Dynamics.b2BodyDef;
	import Box2D.Dynamics.b2FixtureDef;
	import Box2D.Dynamics.b2World;
	
	import mx.collections.ArrayCollection;
	
	import spark.components.supportClasses.SkinnableComponent;
	import com.flexmojo.physics.PhysicsLayout;
	
	public class DefaultPhysicsAdapter implements IPhysicsAdapter
	{
		/**
		 * Subclasses probably want to override this method. This is the trickiest part of
		 * converting a flex component into a physical fixture.
		 * 
		 */
		protected function createShapes(comp:SkinnableComponent):ArrayCollection {
			var shapes:ArrayCollection = new ArrayCollection();
			
			// Default to a rectangle
			var box:b2PolygonShape = new b2PolygonShape();
			var halfWidth:Number = comp.width/(2*PhysicsLayout.PPM);
			var halfHeight:Number = comp.height/(2*PhysicsLayout.PPM);
			box.SetAsOrientedBox(halfWidth, halfHeight, new b2Vec2(halfWidth, halfHeight));
			shapes.addItem(box);

			return shapes;
		}

		public function createBody(comp:SkinnableComponent, world:b2World):b2Body {
			var bodyDef:b2BodyDef = createBodyDef(comp);
			var body:b2Body = world.CreateBody(bodyDef);
			var fixDefs:ArrayCollection = createFixDefs(comp);
			for each (var fixDef:b2FixtureDef in fixDefs) {
				body.CreateFixture(fixDef);
			}
			return body;
		}
		
		protected function createFixDefs(comp:SkinnableComponent):ArrayCollection {
			var fixDefs:ArrayCollection = new ArrayCollection();
			for each (var shape:b2Shape in createShapes(comp)) {
				var fixtureDef:b2FixtureDef = new b2FixtureDef();
				fixtureDef.shape = shape;
				if(comp.getStyle("density")) fixtureDef.density = comp.getStyle("density");
				if(comp.getStyle("friction")) fixtureDef.friction = comp.getStyle("friction");
				if(comp.getStyle("restitution")) fixtureDef.restitution = comp.getStyle("restitution");
				fixDefs.addItem(fixtureDef);
			}
			return fixDefs;
		}
		
		protected function createBodyDef(comp:SkinnableComponent):b2BodyDef {
			var bodyDef:b2BodyDef = new b2BodyDef();
			bodyDef.type = comp.getStyle("staticBody") == true ? b2Body.b2_staticBody : b2Body.b2_dynamicBody;
			bodyDef.position.Set(comp.x/PhysicsLayout.PPM, comp.y/PhysicsLayout.PPM);
			bodyDef.angle = comp.rotation * Math.PI / 180;
			bodyDef.userData = comp;
			if(comp.getStyle("fixedRotation") == true) bodyDef.fixedRotation = comp.getStyle("fixedRotation");
			return bodyDef;
		}

	}
}