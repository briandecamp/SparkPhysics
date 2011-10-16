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
package com.flexmojo.physics.factory
{
	import Box2D.Collision.Shapes.b2CircleShape;
	import Box2D.Collision.Shapes.b2Shape;
	import Box2D.Common.Math.b2Vec2;
	
	import com.flexmojo.physics.PhysicsLayout;
	
	import mx.collections.ArrayCollection;
	
	import spark.components.supportClasses.SkinnableComponent;

	public class CirclePhysicsFactory extends DefaultPhysicsFactory
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