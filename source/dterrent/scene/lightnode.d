/**
	Defines a light Node which can be included in a Scene

	Authors: Poggel / Fr3nchK1ss
	Copyright: Contact Fr3nchK1ss

	TODO: shader integration seems totally neglected. Need a rewrite
 */

module dterrent.scene.lightnode;
import dterrent.system.logger;

import dterrent.scene.scene;
import dterrent.scene.node;
import dterrent.core.color;
import dterrent.core.math;
import std.math; // PI


/**
 * LightNodes are Nodes that emit light.

 * Opengl hardware lights are used by default, but shaders can be used to go
 * beyond their capabilities.
 *
 * All color values are floating point in the range from 0 to 1 and in the order
 * of red, green, blue and alpha.  For example,
 * (1, .5, 0, 0) is orange, since it is 100% red and 50% green.
 *
 * Spotlights default to shining in the -z direction (the same as the default looking direction of the camera).
 * They can be rotated by rotating the Node itself.
 *
 */
class LightNode : Node
{
	/// Values that can be assigned to type.
	enum Type
	{	DIRECTIONAL,	/// A light that shines in one direction through the entire scene
		POINT,			/// A light that shines outward in all directions
		SPOT			/// A light that emits light outward from a point in a single direction
	}
 	Type type = Type.POINT; /// The type of light (directional, point, or spot)

	Color ambient = {r:0,   g:0,   b:0,   a:255}; /// Ambient color of the light.  Defaults to black
	Color diffuse = {r:255, g:255, b:255, a:255}; /// Diffuse color of the light.  Defaults to 100% white.
	Color specular= {r:255, g:255, b:255, a:255}; /// Specular color of the light, defaults to 100% white.

	/**
	 * Spotlight angle of the light, in radians.
	 * If the light type is a spotlight, this is the angle of the light cone. */
	float spotAngle = 45.0 * PI/180;

	/**
	 * Spotlight exponent of the light.
	 * If the light type is a spotlight, this is how focussed the light is.
	 * Larger values produce brighter concentrations of light in the center of the circle
	 * A value of 0 provides an even distribution of light across the entire spot circle. */
	float spotExponent = 0;


	// properties I wish were private or would go away
	public float quadAttenuation = 1.52e-5;	// (1/256)^2, radius of 256, arbitrary
	public vec3 cameraSpacePosition; // Used internally to store the position in camera-space.

	this()
	{	// default constructor required for clone.
	}
	this(Node parent) /// ditto
	{	super(parent);
	}

	alias clone = Node.clone; // TODO learn why GDC said i needed this
	/**
	 * Make a duplicate of this node, unattached to any parent Node.
	 * Params:
	 *     children = recursively clone children (and descendants) and add them as children to the new Node.
	 		destination = destination of the clone if any
	 * Returns: The cloned Node. 
	 */
	LightNode clone(bool children=false, LightNode destination=null)
	{	auto result = cast(LightNode)super.clone(children, destination);

		result.quadAttenuation = quadAttenuation;
		result.type = type;
		result.ambient = ambient;
		result.diffuse = diffuse;
		result.specular = specular;
		result.spotAngle = spotAngle;
		result.spotExponent = spotExponent;

		return result;
	}

	/** Get / set the radius of the light.  Default value is 256.
	 *  Quadratic attenuation is used, so the brightness of an object is Radius^2/distance^2,
	 *  Using this formula, a brightness of 1.0 or higher is 100% bright
	 */
	float getLightRadius()
	{	return sqrt(1/quadAttenuation);
	}
	void setLightRadius(float radius) /// ditto
	{	quadAttenuation = 1.0/(radius*radius);
	}

	/**
	 * Get the quadratic attenuation calculated from the light's radius. */
	float getQuadraticAttenuation()
	{	return quadAttenuation;
	}

	/**
	 * Return the RGB brightness this light contributes to a given point in 3D space, relative to this light's scene.
	 * OpenGl's fixed-function, traditional lighting calculations are used.
	 * The diffuse and ambient values of the light are taken into effect,
	 * while the specular is not, since it depends on the viewing angle of the camera.
	 * Also note that this does not take into account shadows or anything of that nature.
	 * Params:
	 *     point = 3D coordinates of the point to be evaluated.
	 *     margin = For spotlights, setting a margin cause this function to return brightest point inside
	 *         of that radius, instead of the default of a single point.
	 *         This is used internally for nodes that have a spotlight shine on one corner of them
	 *         but not at all at their center.*/
	Color getBrightness(vec3 point, float margin=0.0)
	{
		// Directional lights are easy, since they don't depend on which way the light points
		// or how far away the light is.
		if (type==Type.DIRECTIONAL)
			return Color(ambient.r+diffuse.r, ambient.g+diffuse.g, ambient.b+diffuse.b);

		// light_direction is vector from light to point
		mat4 wTransform = getWorldTransform();
		vec3 light_direction = point - vec3(wTransform[0][3], wTransform[1][3], wTransform[2][3]);
		// distance squared to light
		float d2 = light_direction.x*light_direction.x + light_direction.y*light_direction.y + light_direction.z*light_direction.z;
		float intensity = d2!=0 ? 1/(quadAttenuation*d2) : 1;	// quadratic attenuation.

		bool add_ambient = true;	// Only if this node is in the spotlight
		if (type==Type.SPOT)
		{
			float d = sqrt(d2);	// distance
			if (d==0)
				d=.000000001; // arbitrarily small

			// transform_abs.v[8..11] is the opengl default spotlight direction (0, 0, 1),
			// rotated by the node's rotation.  This is opposite the default direction of cameras
			//float spotDot = Vec3f(transform_abs.v[8..11]).normalize().dot(light_direction/d);
			const float spotDot = dot(getRotation().normalized, light_direction/d);

			// Extra spotlight angle (in radians) to satisfy margin distance
			const float extraAngle = margin>0 ? atan2(margin, d) : 0;

			const float cutoff = cos(spotAngle + extraAngle);
			if (spotDot > cutoff) // TODO some surfaces that should receive light don't.
			{	// Normally this would work except it doesn't take into account the margin.
				//intensity *= pow(spotDot, spotExponent);
				// So instead we just ignore the spotExponent.  This gives an incorrect result for spotlights with
				// a spot exponent other than 1, but it still works well enough for VisibleNode.getLights.
			}
			else
			{	intensity = 0;	// if the spotlight isn't shining on this point.
				add_ambient = false;
		}	}

		// color will store the RGB color values of the intensity.
		assert(intensity != float.infinity);
		const float scale = (1f/255f) * intensity;
		vec3 color = vec3(diffuse.r*scale, diffuse.g*scale, diffuse.b*scale);
		if (add_ambient)
			color += ambient.toVec3;	// diffuse scaled by intensity plus ambient.

		return Color(color);
	}

	/*
	 * This should be protected, but making it anything but public causes it not to be called.
	 * Perhaps it's a dmd bug? */
	override public void ancestorChange(Node old_ancestor)
	{	super.ancestorChange(old_ancestor); // must be called first so scene is set.

		const Scene old_scene = old_ancestor ? old_ancestor.getScene() : null;
		if (scene !is old_scene)
		{	if (old_scene)
				old_ancestor.getScene().removeLight(this);
			if (scene)
				scene.addLight(this);
		}
	}


	int opCmp( LightNode rd) const
	{
        return 0;
	}
}
