import bpy, csv

#Change these Variables based on imports
#Double \\ for proper file paths in Python.
race = "rig-humemale"
boneRenameCSV = 'C:\\Users\\trist\\OneDrive\\Documents\\XIRemix_Scripts\\Blender\\HumeMale_BoneRename.csv'
importListCSV = 'C:\\Users\\trist\\OneDrive\\Documents\\XIRemix_Scripts\\Blender\\HuMa-Import.csv'

from csv import reader
with open(importListCSV, 'r') as import_obj:
    importList = csv.reader(import_obj, delimiter=',')
    for importItem in importList:
        bpy.ops.import_scene.fbx(filepath=importItem[0],ignore_leaf_bones=True,automatic_bone_orientation=True)

        #Used for the rename of bones
        context = bpy.context
        obj = context.object
        
        #Imports the Bone Rename CSV and changes all the bone names.
        with open(boneRenameCSV, 'r') as read_obj:
            bones = csv.reader(read_obj, delimiter=',')
            for bone in bones:
                ob = obj.pose.bones.get(bone[0])
                if ob != None:
                    ob.name = bone[1]
                else:
                    print("My object does not exist.")
                    
        #Renames the imported rig to the race specified.
        rig = bpy.data.objects.get("bone0000")
        rig.name = race
        
        #Exports The scene as an fbx file according to the file path specified in the 2nd slot.
        bpy.ops.export_scene.fbx(filepath=importItem[1],add_leaf_bones=False)
        
        #Removes the children from the scene and prepares for next import
        for child in rig.children:
            bpy.data.objects.remove(child, do_unlink=True)
    
        bpy.data.objects.remove(rig, do_unlink=True)