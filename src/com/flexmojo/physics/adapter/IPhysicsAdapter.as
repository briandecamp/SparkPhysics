package com.flexmojo.physics.adapter
{
	import Box2D.Dynamics.b2Body;
	import Box2D.Dynamics.b2World;
	
	import spark.components.supportClasses.SkinnableComponent;

	public interface IPhysicsAdapter
	{
		function createBody(comp:SkinnableComponent, world:b2World):b2Body;
	}
}
