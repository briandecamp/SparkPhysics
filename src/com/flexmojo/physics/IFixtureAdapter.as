package com.flexmojo.physics
{
	import Box2D.Dynamics.b2Fixture;
	import Box2D.Dynamics.b2World;
	
	import mx.collections.ArrayCollection;
	
	import spark.components.supportClasses.SkinnableComponent;

	public interface IFixtureAdapter
	{
		function createFixtures(comp:SkinnableComponent, world:b2World):ArrayCollection; // of b2Fixture
	}
}