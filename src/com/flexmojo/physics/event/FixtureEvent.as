package com.flexmojo.physics.event
{
	import Box2D.Dynamics.b2Fixture;
	
	import flash.events.Event;
	
	public class FixtureEvent extends Event
	{
		public var fixture:b2Fixture;
		public static const FIXTURE_SELECTED:String = "fixtureSelected";
		
		public function FixtureEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}