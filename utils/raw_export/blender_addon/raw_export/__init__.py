# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2023 Aziroshin (Christian Knuchel)
import json
import pprint
from abc import abstractmethod, ABC
from json import JSONEncoder
from pathlib import Path
from typing import List, Dict, TypeVar, Type, Literal, TypeAlias, Iterable, TypedDict, \
    NamedTuple
# Blender
import bpy
import bpy.types
import bmesh
from bmesh.types import BMesh, BMVert, BMFace, BMLayerItem, BMLoopUV
from mathutils import Vector

bl_info = {
    "name": "raw_export",
    "author": "Aziroshin",
    "description": "Experiment in exporting mesh data via JSON.",
    "blender": (3, 5, 0),
    "version": (0, 0, 0),
    "warning": "This might break all your things."
}

T = TypeVar("T")

###########################################################################


###########################################################################
# Config
###########################################################################
DEVFIXTURE_output_path = "../../../../assets/parts/raw_export_test_cube.json"
###########################################################################


###########################################################################


###########################################################################


def bmvert_location_as_vector(vert: BMVert) -> Vector:
    return Vector((vert.co.x, vert.co.y, vert.co.z))


# TODO [typing]: Find a way to type `iterable4`, which is supposed to
#  receive a value from `diffuse_color` of `Material`
#  (which is `bpy_prop_array`).
def iterable4_to_vector(iterable: Iterable) -> Vector:
    return Vector((item for item in iterable))
    # return Vector((iterable4[0], iterable4[1], iterable4[2], iterable4[3]))


def get_all_uv_coords() -> List[Vector]:
    # This snippet looks promising, based on:
    # https://blender.stackexchange.com/questions/3532/obtain-uv-selection-in-python
    bpy.ops.object.mode_set(mode='OBJECT')
    bpy.context.object.update_from_editmode()

    mesh: BMesh = bpy.context.object.data
    uv_map: bpy.types.MeshUVLoopLayer = mesh.uv_layers.active
    all_uv_coords: list[Vector] = [uv_coord.vector for uv_coord in uv_map.uv]

    return all_uv_coords


class MeshVertex:
    vector: Vector
    uv_coords: List[Vector]

    def __init__(self, vector: Vector, uv_coords: List[Vector]):
        self.vector = vector
        self.uv_coords = uv_coords

    def has_uv_coord(self, prospective_uv_coord) -> bool:
        for uv_coord in self.uv_coords:
            if prospective_uv_coord == uv_coord:
                return True
        return False


class MeshFace:
    vertex_count: int
    mesh_vertices: List[MeshVertex]

    def add_vertex(self, vector, uv_coords) -> None:
        self.mesh_vertices.append(MeshVertex(vector, uv_coords))
        self.vertex_count += 1

    def has_uv_coords(self, uv_coords: List[Vector]) -> bool:
        """Will also return False if either .mesh_vertices or
        uv_coords are empty."""
        if len(self.mesh_vertices) == 0 or len(uv_coords) == 0:
            return False

        uv_coord_matches = 0
        for mesh_vertex in self.mesh_vertices:
            for uv_coord in uv_coords:
                if mesh_vertex.has_uv_coord(uv_coord):
                    uv_coord_matches += 1

        if uv_coord_matches == len(uv_coords) - 1:
            return True
        else:
            return False


# def do_we_get_tessface_obj_with_this():
#     """No, apparently this doesn't have such attributes. :["""
#     obj = bpy.context.active_object
#     return obj.to_mesh(preserve_all_data_layers=True)


def get_equally_split_list(unsplit_list: list[T], part_len: int) -> list[list[T]]:
    split_list = []

    current_set = []
    split_list.append(current_set)
    i_split_list = 0
    for item in unsplit_list:
        current_set.append(item)
        if i_split_list < part_len:
            i_split_list += 1
        else:
            i_split_list = 0
            current_set = []
            split_list.append(current_set)

    return split_list


def get_frozen_vector_copy(vector: Vector) -> Vector:
    vector_copy = vector.copy()
    vector_copy.freeze()
    return vector_copy


class JSONSerializable:
    # TODO: Might want to make this an OrderedDict, so the
    #   resulting JSON is always the same, no matter what.
    @abstractmethod
    def __to_json_serializable__(self):
        pass


class JSONVectorEncoder(JSONEncoder):
    def default(self, vector):
        if isinstance(vector, Vector):
            try:
                vector.z
            except AttributeError:
                # 2D Vector.
                return vector.x, vector.y

            try:
                vector.w
            except AttributeError:
                # 3D Vector.
                return vector.x, vector.y, vector.z

            # 4D Vector.
            return vector.x, vector.y, vector.z, vector.w

        # We try this last, just for the (albeit unlikely) case that
        # JSONEncoder all of a sudden gets support for mathutils.Vector
        # one day, in which case it would get serialized by that
        # instead, with potentially slight differences in schema,
        # which could result in weird bugs.
        return super().default(vector)


class JSONEncoderByMethod(JSONEncoder):
    def default(self, item):
        if hasattr(item, "__to_json_serializable__"):
            return item.__to_json_serializable__()

        return super().default(item)


TJSONEncoder = TypeVar("TJSONEncoder", bound=JSONEncoder, covariant=True)


class EmptyJSONEncoderChainError(Exception):
    pass


class JSONEncoderChain(JSONEncoder):
    @staticmethod
    @abstractmethod
    def encoder_classes() -> List[Type[TJSONEncoder]]:
        return []

    encoders: List[JSONEncoder] = []

    def __init__(
        self,
        *,
        skipkeys=False,
        ensure_ascii=True,
        check_circular=True,
        allow_nan=True,
        sort_keys=False,
        indent=None,
        separators=None,
        default=None
    ):
        super().__init__(
            skipkeys=skipkeys,
            ensure_ascii=ensure_ascii,
            check_circular=check_circular,
            allow_nan=allow_nan,
            sort_keys=sort_keys,
            indent=indent,
            separators=separators,
            default=default
        )
        for encoder_class in self.encoder_classes():
            self.encoders.append(
                encoder_class(
                    skipkeys=skipkeys,
                    ensure_ascii=ensure_ascii,
                    check_circular=check_circular,
                    allow_nan=allow_nan,
                    sort_keys=sort_keys,
                    indent=indent,
                    separators=separators,
                    default=default
                )
            )

    def default(self, item):
        encoders_tried = 0
        for encoder in self.encoders:
            try:
                return encoder.default(item)
            except TypeError as error:
                encoders_tried += 1
                if encoders_tried < len(self.encoders):
                    continue
                else:
                    # This is the last encoder, so we're out of options.
                    raise error

        raise EmptyJSONEncoderChainError(
            f"There are no encoders defined for {self.__class__.__name__}."
        )


class AllJSONEncoders(JSONEncoderChain):
    @staticmethod
    def encoder_classes() -> List[Type[TJSONEncoder]]:
        # TODO [bug,typing]: The return value's typing doesn't seem to work,
        #   e.g. adding a number to the list doesn't result in an error.
        return [
            JSONVectorEncoder,
            JSONEncoderByMethod,
            JSONEncoder
        ]


def get_linked_output_nodes(node: bpy.types.Node) -> List[bpy.types.Node]:
    linked_output_nodes: List[bpy.types.Node] = []  # Type: https://docs.blender.org/api/current/bpy.types.Node.html#bpy.types.Node

    outputs: bpy.types.NodeOutputs = node.outputs  # Type: https://docs.blender.org/api/current/bpy.types.NodeOutputs.html#bpy.types.NodeOutputs
    for output in node.outputs:
        for link in output.links:
            # TODO: Traverse the `to_node`s of link until a
            #   valid end node is found. Only a valid end
            #   node will make this a valid image texture
            #   for export.

            # The type of `link` is `NodeLink`.
            link: bpy.types.NodeLink = link
            linked_output_nodes.append(link.to_node)
    return linked_output_nodes


def get_end_nodes(node: bpy.types.Node) -> List[bpy.types.Node]:
    end_nodes: List[bpy.types.Node] = []  # Type: https://docs.blender.org/api/current/bpy.types.Node.html#bpy.types.Node

    for linked_output_node in get_linked_output_nodes(node):
        end_nodes += get_end_nodes(linked_output_node)

    if len(end_nodes) == 0:  # Outputs not linked to any nodes.
        end_nodes.append(node)

    return end_nodes


MaterialDataTypeStr: TypeAlias = Literal[
    "DEFAULT",
    "BASIC",
    "IMAGE_FILES"
]


class MaterialData(ABC, JSONSerializable):
    type: MaterialDataTypeStr
    index: int
    name: str


class DefaultMaterialData(MaterialData):

    def __init__(self, index: int):
        self.type = "DEFAULT"
        self.index = index
        self.name = "Default"

    def __to_json_serializable__(self):
        return {
            "index": self.index,
            "type": self.type,
            "name": self.name,
        }


class BasicMaterialData(MaterialData):
    color: Vector

    def __init__(self, index: int, name: str, color: Vector):
        self.type = "BASIC"
        self.index = index
        self.name = name
        self.color = color

    def __to_json_serializable__(self):
        return {
            "index": self.index,
            "type": self.type,
            "name": self.name,
            "color": self.color
        }


class ImageTextureMaterialData(MaterialData):
    filenames: List[str]

    def __init__(self, index: int, name: str, filenames: List[str] = []):
        self.type = "IMAGE_FILES"
        self.index = index
        self.name = name
        self.filenames = filenames

    def add_file_name(self, filename: str) -> None:
        self.filenames.append(filename)

    def __to_json_serializable__(self):
        return {
            "index": self.index,
            "type": self.type,
            "name": self.name,
            "filenames": self.filenames
        }


class DebugCubeTriDict(TypedDict):
    axis: Literal["x", "y", "z"]
    axis_sign: Literal["+", "-"]
    vertices: List[Vector]
    uvs: List[Vector]


class DebugCubeFaceDict(TypedDict):
    tris: List[DebugCubeTriDict]


class DebugCubeSideDict(TypedDict):
    faces_match: bool
    faces: List[DebugCubeFaceDict]


class AxisSignInfo(NamedTuple):
    axis: Literal["x", "y", "z"]
    sign: Literal["+", "-"]


def get_cube_same_sign_axis_info(vectors: List[Vector]) -> AxisSignInfo:
    """Determines axis and sign of a test cube side by a list of vectors.
    This strictly assumes a cube centered on the world origin with each side
    being made up of two triangles. Behaviour outside these parameters is
    undefined."""

    axes: List[Literal["x"], Literal["y"], Literal["z"]] = ["x", "y", "z"]
    columns: List[List[float]] = [
        [vectors[0].x, vectors[1].x, vectors[2].x],
        [vectors[0].y, vectors[1].y, vectors[2].y],
        [vectors[0].z, vectors[1].z, vectors[2].z]
    ]

    i_axes = 0
    for column in columns:
        if all(map(lambda component: component > 0, column)):
            return AxisSignInfo(axes[i_axes], "+")
        elif all(map(lambda component: component < 0, column)):
            return AxisSignInfo(axes[i_axes], "-")
        i_axes += 1


def generate_cube_debug_side_list(pre_json: Dict) -> List[DebugCubeSideDict]:
    sides: List[DebugCubeSideDict] = []
    pre_json_vertices: List[Vector] = pre_json["vertices"]
    pre_json_uvs: List[Vector] = pre_json["uvs"]
    vertex_count = len(pre_json_vertices)

    if not vertex_count % 6 == 0:
        raise TypeError(
            "Number of vertices must be divisible by 6, "
            "as one side consists of two tris (with two overlapping)."
        )

    side_count = int(vertex_count / 6)
    for i_side in range(side_count):
        verts: List[Vector] = [pre_json_vertices[6*i_side+i] for i in range(6)]
        uvs: List[Vector] = [pre_json_uvs[6*i_side+i] for i in range(6)]
        tri1_axis_sign_info: AxisSignInfo =\
            get_cube_same_sign_axis_info(verts[:3])
        tri2_axis_sign_info: AxisSignInfo =\
            get_cube_same_sign_axis_info(verts[3:])

        sides.append({
                "faces_match": tri1_axis_sign_info == tri1_axis_sign_info,
                "faces": [
                    {
                        "axis": tri1_axis_sign_info.axis,
                        "axis_sign": tri1_axis_sign_info.sign,
                        "vertices": verts[:3],
                        "uvs": uvs[:3]
                    },
                    {
                        "axis": tri2_axis_sign_info.axis,
                        "axis_sign": tri2_axis_sign_info.sign,
                        "vertices": verts[3:],
                        "uvs": uvs[3:]
                    },
                ]
        })

    return sides


class RawExport(bpy.types.Operator):
    bl_idname = "object.raw_export"
    bl_label = "raw_export"

    # This maps the uv-coordinates to their vertices.
    # One uv-coordinate can map to more than one vertex if there are
    # multiple faces that are mapped to the same UV coord.
    # However, with this it will be clear for each vertex to which
    # uv-coord it maps, and with the sorting depending on the uv-coord
    # list, which is already face-sorted, the vertices and their uv-coords
    # will be properly groupable as belonging to a particular face.
    def execute(self, context) -> set[str]:
        # Defaults
        y_up_default = True

        # Options
        make_y_up = True

        # Input - prototypal, might come from somewhere else eventually.
        face_count = 4

        mesh: BMesh = bmesh.new()
        obj: bpy.types.ObjectBase = bpy.context.active_object
        mesh.from_mesh(obj.data)
        uv_layer: BMLayerItem = mesh.loops.layers.uv.active

        vertices_pre_json: List[Vector] = []
        normals_pre_json: List[Vector] = []
        uvs_pre_json: List[Vector] = []
        indices_pre_json = []
        material_indices_pre_json = []
        material_data_pre_json: Dict[int, Dict] = {}

        # === The Action ===

        material_index = 0
        materials_pre_json: List[MaterialData] = []

        # material: bpy.types.Material
        # material_slots: List[MaterialSlot]
        for material in [slot.material for slot in obj.material_slots]:
            if material:
                # The "use_nodes"-case is currently solely focused on getting image paths.
                if material.use_nodes:
                    for node in material.node_tree.nodes:  # node:  bpy.types.Node
                        if type(node) == bpy.types.ShaderNodeTexImage:
                            # Make sure it's not some disconnected node (like one for normal baking),
                            # but one that ultimately feeds into a "Material Output" node.
                            image_filenames = []
                            for end_node in get_end_nodes(node):
                                if type(end_node) == bpy.types.ShaderNodeOutputMaterial:
                                    image_filenames.append(Path(node.image.filepath).name)

                            materials_pre_json.append(ImageTextureMaterialData(
                                index=material_index,
                                name=material.name,
                                filenames=image_filenames
                            ))
                else:
                    materials_pre_json.append(BasicMaterialData(
                        index=material_index,
                        name=material.name,
                        color=iterable4_to_vector(material.diffuse_color)
                    ))
            else:
                materials_pre_json.append(DefaultMaterialData(
                    index=material_index
                ))

            material_index += 1

        # Create a lookup table where you can put in a uv coord (2D) and get
        # out the corresponding vertex position (3D).
        #
        # NOTE: Potential problem: For example, a cube where every 3D face maps
        # to the same uv coordinates would get mapped in the order of uv
        # "faces". This might mess with the order/grouping the vertices have on
        # the 3D side.
        vert_by_uv: Dict[Vector, BMVert] = {}
        for face in mesh.faces:
            face: BMFace = face
            material_indices_pre_json.append(face.material_index)
            for vert in face.verts:
                for loop in vert.link_loops:
                    loop_uv_layer_data: BMLoopUV = loop[uv_layer]
                    uv_coord: Vector = loop_uv_layer_data.uv
                    vert_by_uv[get_frozen_vector_copy(uv_coord)] = vert
        all_uv_coords: list[Vector] = get_all_uv_coords()  # They already come sorted by face.
        uv_coords_grouped_by_face: list[list[Vector]] = get_equally_split_list(all_uv_coords, face_count)

        for face_uv_coords in uv_coords_grouped_by_face:
            for vert_uv_coord in face_uv_coords:
                vert = vert_by_uv[get_frozen_vector_copy(vert_uv_coord)]

                vertices_pre_json.append(bmvert_location_as_vector(vert))
                normals_pre_json.append(vert.normal)
                uvs_pre_json.append(vert_uv_coord)
                indices_pre_json.append(vert.index)

                # print("UV:", vert_uv_coord, "Vert:", vert_by_uv[get_frozen_vector_copy(vert_uv_coord)])

        mesh_pre_json = {
            "vertices": vertices_pre_json,
            "normals": normals_pre_json,
            "uvs": uvs_pre_json,
            "indices": indices_pre_json,
            "material_indices": material_indices_pre_json,
            # List version of `materials`.
            "materials": [
                materials_pre_json[index] for index in range(material_index)
            ]
            # Dict version of `materials`.
            # "materials": {
            #     index: materials_pre_json[index] for index in range(material_index)
            # }
        }

        pprint.pprint(generate_cube_debug_side_list(mesh_pre_json), indent=4)

        with open(DEVFIXTURE_output_path, "w") as output_file:
            output_file.write(json.dumps(mesh_pre_json, cls=AllJSONEncoders, indent=4))

        return {"FINISHED"}


def register():
    bpy.utils.register_class(RawExport)


def unregister():
    bpy.utils.unregister_class(RawExport)
