package com.flexmojo.physics.adapter
{
	import Box2D.Collision.Shapes.b2CircleShape;
	import Box2D.Collision.Shapes.b2Shape;
	import Box2D.Common.Math.b2Vec2;
	
	import com.flexmojo.physics.PhysicsLayout;
	
	import mx.collections.ArrayCollection;
	
	import spark.components.supportClasses.SkinnableComponent;

	public class CirclePhysicsAdapter extends DefaultPhysicsAdapter
	{
		override protected function createShapes(comp:SkinnableComponent):Vector.<b2Shape> {
			var shapes:Vector.<b2Shape> = new Vector.<b2Shape>(1, true);
			var radius:Number = comp.width/(2*PhysicsLayout.PPM);
			var circle:b2CircleShape = new b2CircleShape();
			circle.SetRadius(radius);
			circle.SetLocalPosition(new b2Vec2(radius, radius));
			shapes[0] = circle;
			return shapes;
		}
	}
}