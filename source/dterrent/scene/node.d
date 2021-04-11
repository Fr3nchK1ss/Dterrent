/**
	Authors: Fr3nchK1ss on github
	Copyright: proprietary / contact dev

 */

module dterrent.scene.node;
import dterrent.system.logger;

import std.format;
import dterrent.core;
import dterrent.scene.scene;
import std.math: cos, acos;

/**
 * Nodes are used for building scene graphs in Yage.
 * Every node has an array of child nodes as well as a parent node, with
 * the exception of a Scene that exists at the top of the scene graph and has no parent.
 * When one node is moved or rotated, all of its child nodes move and rotate as well.
 * Likewise, setting the position or rotation of a node does so relative to its parent.
 * Rendering is done recursively from the Scene down through every child node.
 * Likewise, updating of position and rotation occurs recursively from Scene's update() method.
 *
 * All other Nodes extend this class.
 * Methods for modifying the hierarchy of Nodes (parents, children) are defined here.
 *
 * Example:
 * --------
 * Scene s = new Scene();
 * Node a = s.addChild(new Node());  // a is a child of s, it exists in Scene s.
 * a.setPosition(3, 5, 0);           // Position is set relative to 0, 0, 0 of the entire scene.
 * a.setRotation(0, 3.14, 0);        // a is rotated PI radians (180 degrees) around the Y axis.
 *
 * SpriteNode b = new SpriteNode(a); // b is a child of a, therefore,
 * b.setPosition(5, 0, 0);           // its positoin and rotation are relative to a's.
 * b.getWorldPosition();             // Returns vec3(-2, 5, 0), b's position relative to the origin.
 *
 * s.addChild(b);                    // b is now a child of s.
 * b.getWorldPosition();             // Returns vec3(5, 0, 0), since it's position is relative
 *                                   // to 0, 0, 0, instead of a.
 * --------
 */
class Node : Tree!(Node), IDisposable
{
	package static ContiguousTransforms orphanTransforms; // stores transforms for nodes that don't belong to any scene
	package int transformIndex = -1; // Index of the transform structure in the scene's nodeTransforms array.
	package Scene scene; // The Scene that this node belongs to.
	Event!() onUpdate; /// If set, call this function instead of the standard update function.

	// Contract programming
	invariant()
	{
		assert(parent !is this);
	}

	this()
	{
	}

	/**
     * To create a node with a default Transform. Used in unittests
     */
	this(bool hasTransform)
	{
		if (hasTransform)
			transformIndex = orphanTransforms.addNew(this);
	}

	this(Node parent) /// ditto
	{
		if (parent)
		{
			parent.addChild(this); // calls ancestorChange()
			// If parent has a Transform, give child a Transform
			if (parent.transformIndex != -1)
				transformIndex = orphanTransforms.addNew(this);

		}
		else
			ancestorChange(null);

		onUpdate.listenersChanged = () {
			this.transform().onUpdateSet = this.onUpdate.length > 0;
		};

	}

	/**
	 * Add a child Node to this Node's array of children.
	 * Overridden to call ancestorChange() and mark transformation matrices dirty.
	 * If child is already a child of this node, do nothing.
	 * Params:
	 *     child = The Node to add.
	 * Returns: The child Node that was added.  Templating is used to ensure the return type is exactly the same.*/
	T addChild(T : Node)(T child)
	{
		assert(child !is this);
		assert(child !is parent);
		assert(child.transformIndex == -1 || child.transform().node is child);

		auto oldParent = child.getParent();
		super.addChild(child);
		if (oldParent !is null && oldParent !is this)
			child.ancestorChange(oldParent);
		return child;
	}

	/**
	 * Remove a child Node to this Node's array of children.
	 * Overridden to call ancestorChange() and mark transformation matrices dirty.
	 * Params:
	 *     child = The Node to remove.
	 * Returns: The child Node that was removed.  Templating is used to ensure the return type is exactly the same.*/
	T removeChild(T : Node)(T child) //
	{
		auto oldParent = child.getParent();
		super.removeChild(child);
		child.ancestorChange(oldParent); // sets worldDirty also
		return child;
	}

	/**
	 * Make a duplicate of this node, unattached to any parent Node.
	 * Params:
	 *     cloneChildren = recursively clone children (and descendants) and add them as children to the new Node.
	 * Returns: The cloned Node. */
	Node clone(bool cloneChildren = true, Node destination = null) /// ditto
	{

		if (!destination)
			destination = cast(Node) this.classinfo.create(); // why does new typeof(this) fail?
		assert(destination);

		if (destination.transformIndex != -1)
		{
			*destination.transform = *transform;
			destination.transform.node = destination;
			destination.transform.parent = destination.parent ? destination.parent.transform()
				: null;
			destination.transform.worldDirty = true;
		}

		/* TODO: Events aren't cloned.
		destination.onUpdate = onUpdate;*/

		if (cloneChildren)
			foreach (c; this.children)
			{
				auto copy = cast(Node) c.classinfo.create();
				destination.addChild(c.clone(true, copy));
			}

		return destination;
	}

	unittest
	{
		tracef("Test child cloning");
		auto a = new Node();
		a.addChild(new Node());
		auto b = a.clone();
		assert(b.getChildren().length == 1);
		assert(b.getChildren()[0] != a.getChildren()[0]); // should not be equal, should've been cloned.
	}

	/**
	 * Some types of Nodes may need to free resources before being destructed.
     */
	override void dispose()
	{
		import std.range : retro;

		if (children.length > 0)
		{
			foreach (c; retro(children))
				c.dispose();
			children.length = 0; // prevent multiple calls.
		}
	}

	/**
	 * Get / set the xyz position of this Node relative to its parent's position. */
	vec3 getPosition()
	{
		return transform.position;
	}

	void setPosition(vec3 position) /// ditto
	{
		setWorldDirty();
		transform.position = position;
	}

	/**
	 * Get / set the rotation of this Node (as an axis-angle vector) relative to its parent's rotation. */
	vec3 getRotation()
	{
		return transform.rotation.to_axis_angle();
	}

	quat getRotationQuatrn()
	{
		return transform.rotation;
	}

	void setRotation(vec3 axisAngle) /// ditto
	{
		setWorldDirty();

		transform.rotation.rotate_axis(
			axisAngle.magnitude,
			axisAngle.normalized
		);
	}

	void setRotation(quat quaternion) /// ditto
	{
		setWorldDirty();
		transform.rotation = quaternion;
	}

	/**
	 * Get / set the xyz scale of this Node relative to its parent's scale. */
	vec3 getScale()
	{
		return transform.scale;
	}

	void setScale(vec3 scale) /// ditto
	{
		setWorldDirty();
		transform.scale = scale;
	}

	/**
	 * Get / set the linear velocity this Node relative to its parent's velocity. */
	vec3 getVelocity()
	{
		if (scene)
			return transform.velocityDelta / scene.increment;
		else
			return transform.velocityDelta;
	}

	void setVelocity(vec3 velocity) /// ditto
	{
		if (scene)
			transform.velocityDelta = velocity * scene.increment;
		else
			transform.velocityDelta = velocity;
	}

	/**
	 * Get / set the angular (rotation) velocity this Node relative to its parent's velocity.
	 */
	vec3 getAngularVelocity()
	{
		return transform.angularVelocity;
	}

	void setAngularVelocity(vec3 axisAngle) /// ditto
	{
		transform.angularVelocity = axisAngle;

		if (scene)
			axisAngle *= scene.increment;

		transform.angularVelocityDelta = quat.axis_rotation(
			axisAngle.magnitude,
			axisAngle.normalized
		);
	}

	unittest
	{
		immutable hasTransform = true;
		Node n = new Node(hasTransform);

		vec3 av1 = vec3(-.5f, .5f, 1.0f);
		n.setAngularVelocity(av1);
		immutable av2 = n.getAngularVelocity();
		import gl3n.math: almost_equal;
		assert(almost_equal(av1.x, av2.x)
			&& almost_equal(av1.y, av2.y)
			&& almost_equal(av1.z, av2.z));
	}

	/**
	 * Get the position, axis-angle rotation, or scale in world coordinates,
	 * instead of relative to the parent Node.
	 */
	vec3 getWorldPosition()
	{
		if (transform.worldDirty) // makes it faster.
			calcWorld();
		return transform.worldPosition;
	}

	vec3 getWorldRotation() /// ditto
	{
		calcWorld();
		return transform.worldRotation.to_axis_angle();
	}

	quat getWorldRotationQuatrn() /// ditto
	{
		calcWorld();
		return transform.worldRotation;
	}

	vec3 getWorldScale() /// ditto
	{
		calcWorld();
		return transform.worldScale;
	}

	/// Bug:  Doesn't take parent's rotation or scale into account
	vec3 getWorldVelocity()
	{
		calcWorld();

		vec3 worldVelocity = transform.velocityDelta;
		if (scene)
			worldVelocity /= scene.increment;
		if (parent)
			worldVelocity += parent.getWorldVelocity();

		return worldVelocity;
	}


	// Convenience functions
	mat4 getTransform()
	{	
		mat4 ret = mat4.identity;
		ret.translate(transform.position);
		ret.set_rotation( transform.rotation.to_matrix!(3,3) );
		//TODO ret.set_scale(matrix)

		return ret;
	}
	mat4 getWorldTransform()
	{
		calcWorld();
		mat4 ret = mat4.identity;
		ret.translate(transform.worldPosition);
		ret.set_rotation( transform.worldRotation.to_matrix!(3,3) );
		//TODO ret.set_scale(worldScale matrix)

		return ret;
	}
	unittest
	{
		tracef("Test getTransform");
		immutable hasTransform = true;
		Node a = new Node(hasTransform);
		a.setPosition(vec3(3, 2, 0.5));
		a.setRotation(vec3(0, 3.1415927, 0));
		mat4 transfo_matrix = a.getTransform();

		// Smooth the result
		import gl3n.math: almost_equal;
		foreach( ref float[4] row; transfo_matrix.matrix )
			foreach( ref e; row)
				if ( almost_equal(e, 0) )
					e = 0;

		//tracef("Transform matrix: %s", transfo_matrix);
		assert( transfo_matrix == [[-1.0f, 0.0f, 0.0f,  3.0f],
                     			   [0.0f,  1.0f, 0.0f,  2.0f],
                     			   [0.0f,  0.0f, -1.0f, 0.5f],
                     			   [0.0f,  0.0f, 0.0f,  1.0f]]);
								
	}

	///
	void move(vec3 amount)
	{
		transform.position += amount;
		setWorldDirty();
	}

	/// 
	void rotate(vec3 axisAngle)
	{
		setRotation(axisAngle);
	}

	///
	void rotate(quat quaternion)
	{
		transform.rotation *= quaternion;
		setWorldDirty();
	}

	///
	void accelerate(vec3 amount)
	{
		if (scene)
			transform.velocityDelta += amount*scene.increment;
		else
			transform.velocityDelta += amount;
	}

	/**
	 * Increase the angular acceleration factor (== angular velocity) by
	 * combining the old velocity with a new axisAngle.
	 */
	void angularAccelerate(vec3 axisAngle)
	{	
		// Need to combine the 2 axis/angle == quaternion multiplication in reverse order
		immutable quat qAA = quat.axis_rotation(axisAngle.magnitude, axisAngle.normalized);
		immutable vec3 newAngularVelocity = (qAA * transform.angularVelocityDelta).to_axis_angle();

		setAngularVelocity(newAngularVelocity);
	}
	unittest
	{
		Node n = new Node(true);//hasTransform
		vec3 av1 = vec3(-.5, .5, 1);
		n.setAngularVelocity(av1);
		n.angularAccelerate(av1);
		immutable vec3 av2 = n.getAngularVelocity();

		av1 *= 2;
		import gl3n.math: almost_equal;
		assert(almost_equal(av1.x, av2.x)
			&& almost_equal(av1.y, av2.y)
			&& almost_equal(av1.z, av2.z));
	}

	/// Get the Scene at the top of the tree that this node belongs to, or null if this is part of a scene-less node tree.
	Scene getScene()
	{
		return scene;
	}

	/**
	* Get the struct containing this Node's transformation data.
    */
	package Node.Transform* transform()
	{
		assert(!scene || (transformIndex >= 0 && transformIndex < scene.nodeTransforms.length),
				format("transformIndex: %d", transformIndex));

		//trace("index = ", transformIndex);
		return scene ? &scene.nodeTransforms.transforms[transformIndex]
			: &orphanTransforms.transforms[transformIndex];
	}

	/*
	 * Set the worldDirty flag on this Node and all of its children, if they're not dirty already.
	 * This should be called whenever a Node has its transformation matrix changed.
	 * This function is used internally by the engine usually doesn't need to be called manually.
	 */
	package void setWorldDirty()
	{
		if (!transform.worldDirty)
		{
			transform.worldDirty = true;
			foreach (ref c; children)
				c.setWorldDirty();
		}
	}

	/**
	 * Calculate the value of the worldPosition, worldRotation, and worldScale.
	 */
	protected void calcWorld()
	{
		if (transform.worldDirty)
		{
			if (parent && parent !is scene)
			{
				parent.calcWorld();

				/* scaling */
				// TODO: change worldScale below to a simple real scalar? 
				// The line below is commented out, there is not vec3*vec3 multiplication with gl3n
				// worldScale is a vec3(1) anyway, and no scaling occurs through demos or anywhere...
				//transform.worldPosition = transform.position * parent.transform.worldScale;
				transform.worldPosition = transform.position;

				/* rotation */
				if (parent.transform.worldRotation != quat.identity) // if parent has rotation
				{
					/* Apply parent rotation to node position */
					quat qWorldPos = quat(0, transform.worldPosition); // vec3 to pure quat
					qWorldPos = parent.transform.worldRotation // TODO: suboptimal
								* qWorldPos
								* parent.transform.worldRotation.conjugated;
					// Round results close to 0
					import gl3n.math: almost_equal;
					if ( almost_equal(qWorldPos.x, 0) ) qWorldPos.x = 0;
					if ( almost_equal(qWorldPos.y, 0) ) qWorldPos.y = 0;
					if ( almost_equal(qWorldPos.z, 0) ) qWorldPos.z = 0;
					transform.worldPosition = vec3(qWorldPos.x, qWorldPos.y, qWorldPos.z);
					
					/* Apply parent rotation to node rotation */
					transform.worldRotation = parent.transform.worldRotation * transform.rotation;
				}
				else
					transform.worldRotation = transform.rotation;

				/* translation */
				transform.worldPosition = transform.worldPosition + parent.transform.worldPosition;
				// Same comment as above, consider changing transform.scale to scalar
				// transform.worldScale =  parent.transform.worldScale * transform.scale;

			}
			else
			{
				transform.worldPosition = transform.position;
				transform.worldRotation = transform.rotation;
				transform.worldScale = transform.scale;
			}
			transform.worldDirty = false;
		}
	}

	unittest
	{
		tracef("Test calcWorld");

		immutable hasTransform = true;
		Node a = new Node(hasTransform);
		a.setPosition(vec3(3, 0, 0));
		a.setRotation(vec3(0, 3.1415927, 0));

		Node b = new Node(a); // child node
		b.setPosition(vec3(5, 0, 0));
		immutable bw = b.getWorldPosition();
		
		//tracef("bw = %s", bw);
		assert(bw == vec3(-2,0,0));

		/* TODO: scale as scalar. See calcWorld */
		//a.setScale(vec3(2, 2, 2));
		//bw = b.getWorldPosition();
		//assert(bw.almostEqual(vec3(-7, 0, 0)), format("%s", bw.v));
	}

	/*
	 * Called after any of a node's ancestors have their parent changed.
	 * This function also sets worldDirty=true
	 * since the world transformation values should always be dirty after an ancestor change.
	 * Params:
	 *    oldAncestor = The ancestor that was previously one above the top node of the tree that had its parent changed. */
	protected void ancestorChange(Node oldAncestor)
	{
		Scene newScene = (parent !is null) ? parent.scene : null;
		auto transforms = (newScene !is null) ? &newScene.nodeTransforms : &orphanTransforms;
		auto oldTransforms = (scene !is null) ? &scene.nodeTransforms : &orphanTransforms;

		if (transforms !is oldTransforms) // changing scene of existing node
		{
			if (transformIndex == -1) // previously didn't belong to a scene
				transformIndex = transforms.addNew(this);
			else
			{
				assert(oldTransforms.transforms[transformIndex].node is this);
				immutable newIndex = transforms.add(transform(), this);
				oldTransforms.remove(transformIndex);
				transformIndex = newIndex;
			}
			scene = newScene;

			// Update the incrementing values to match the scene increment.
			immutable incrementChange = (newScene ? newScene.increment : 1f) / (scene
					? scene.increment : 1f);
			transform.velocityDelta *= incrementChange;
			// velocityDelta as quaternion
			immutable real newMagnitude = cos( acos(transform.angularVelocityDelta.magnitude)*incrementChange );
			transform.angularVelocityDelta.w = newMagnitude;
		}
		else
		{
			if (transformIndex == -1) // a brand new node
				transformIndex = transforms.addNew(this);
		}

		assert(transforms.transforms[transformIndex].node is this);

		transform().parent = (parent && parent !is scene) ? parent.transform() : null;
		transform().worldDirty = true;

		foreach (c; children)
			c.ancestorChange(oldAncestor); // breaks the assertions below!  But how?

		debug
		{
			if (scene)
				assert(0 <= transformIndex && transformIndex < transforms.length);
			else
				assert(transformIndex != -1);
		}
		assert(transform); // assert it is accessible
		assert(transform.worldDirty || !transform.worldDirty);
	}

	unittest
	{
		tracef("Test Node/Scene creation and addChild()");

		immutable hasTransform = true;
		Node a = new Node(hasTransform);
		Node b = new Node(a);
		Node c = new Node(a);
		b.addChild(c);
		a.addChild(c);

		Scene s = new Scene();
		Node d = new Node();
		s.addChild(d);
		s.removeChild(d); //Not removing child causes a segfault, because dispose() is called after end of scope somehow
	}

	/*
	 * A node's transformation values are stored in a consecutive array in its scene, for better cache performance
	 * Or if, it has no scene, this structure is allocated on the heap. */
	struct Transform
	{
		vec3 position;
		quat rotation = quat.identity;
		vec3 scale = vec3(1);

		vec3 velocityDelta; // Velocity times the scene increment, for faster updating.
		vec3 angularVelocity; // Stored as a vector to allow storing rotations beyond -PI to PI
		quat angularVelocityDelta; // Stored as a quaternion for faster updating.

		vec3 worldPosition;
		quat worldRotation;
		vec3 worldScale = vec3(1);

		float cullRadius = 0; // TODO: unionize these with the vectors above for tighter packing once we switch to simd.
		bool worldDirty = true;
		bool onUpdateSet = false;

		Node.Transform* parent; // For fast lookups when calculating world transforms
		Node node; // Pointer back to the node.

		static Transform opCall()
		{
			Transform result;
			return result;
		}

		int opCmp(Transform rd) const
		{
			return 0;
		}
	}

	/**
	 * Stores an array of Node transform data contiguously in memory.
	 * This is more cache friendly and testing shows this greatly increases performance. */
	struct ContiguousTransforms
	{
		Node.Transform[] transforms;

		int add(Node.Transform* transform, Node n)
		{
			transforms ~= *transform;
			transforms[length - 1].node = n;
			return cast(int)(transforms.length) - 1;
		}

		int addNew(Node n)
		{
			transforms ~= Transform();
			transforms[length - 1].node = n;
			return cast(int)(transforms.length) - 1;
		}

		void remove(uint index)
		{
			assert(transforms[index].node.transformIndex == index, format("%d, %d, %s",
					transforms[index].node.transformIndex, index,
					transforms[index].node.classinfo.name));
			if (index+1 != transforms.length )
			{
				transforms[index] = transforms[length - 1]; // move another node no top of the one removed
				transforms[index].node.transformIndex = index; // update the index of the moved node.
			}
			transforms.length = transforms.length - 1;
		}

		ulong length()
		{
			return transforms.length;
		}
	}

}
