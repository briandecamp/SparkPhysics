package com.flexmojo.physics
{
	import Box2D.Collision.Shapes.b2CircleShape;
	import Box2D.Common.Math.b2Vec2;
	
	import mx.collections.ArrayCollection;
	
	import spark.components.supportClasses.SkinnableComponent;

	public class CirclePhysicsAdapter extends DefaultPhysicsAdapter
	{
		override protected function createShapes(comp:SkinnableComponent):ArrayCollection {
			var shapes:ArrayCollection = new ArrayCollection();
			var radius:Number = comp.width/(2*PhysicsLayout.PPM);
			var circle:b2CircleShape = new b2CircleShape();
			circle.SetRadius(radius);
			circle.SetLocalPosition(new b2Vec2(radius, radius));
			shapes.addItem(circle);
			return shapes;
		}
	}
}