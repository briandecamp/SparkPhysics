package com.flexmojo.physics
{
	import Box2D.Dynamics.b2Body;
	import Box2D.Dynamics.b2World;
	
	import spark.components.supportClasses.SkinnableComponent;

	public interface IFixtureAdapter
	{
		function createBody(comp:SkinnableComponent, world:b2World):b2Body;
	}
}
