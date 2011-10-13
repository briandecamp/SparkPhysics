package com.flexmojo.physics
{
	import Box2D.Dynamics.b2Body;

	public interface IPhysicalComponent
	{
		function get physicalBody():b2Body;
		function set physicalBody(b:b2Body):void;
		
	}
}