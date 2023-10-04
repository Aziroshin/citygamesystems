# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2023 Aziroshin (Christian Knuchel)
import json
import pprint
from abc import abstractmethod, ABC
from json import JSONEncoder
from pathlib import Path
from typing import List, Dict, TypeVar, Type, Literal, TypeAlias, Iterable, TypedDict, \
    NamedTuple, Any, Tuple

# Blender
import bpy
import bmesh
from bmesh.types import BMesh, BMVert, BMFace, BMLayerItem
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

    mesh: bpy.types.Mesh = bpy.context.object.data
    uv_map: bpy.types.MeshUVLoopLayer = mesh.uv_layers.active
    all_uv_coords: list[Vector] = [uv_coord.vector for uv_coord in uv_map.uv]

    return all_uv_coords


def get_all_uv_coords_grouped_by_face(face_vertex_count: int) -> list[list[Vector]]:
    all_uv_coords: list[Vector] = get_all_uv_coords()  # They already come sorted by face.
    return get_equally_split_list(all_uv_coords, face_vertex_count)


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


class FractionalListSplitError(Exception):
    pass


def get_equally_split_list(unsplit_list: list[T], part_len: int) -> list[list[T]]:
    part_count = len(unsplit_list)
    if not part_count % part_len == 0:
        raise FractionalListSplitError(
            f"part_len(%s) is not a multiple of the number of items\
            in unsplit_list (%s)." % part_len, part_count
        )
    part_group_count = int(part_count / part_len)
    return [
        unsplit_list[part_len*g:part_len*g+part_len]
        for g in range(part_group_count)
    ]


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


# TODO: Add a __repr__.
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
    material_index: int


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
    pre_json_material_indices: List[int] = pre_json["material_indices"]
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
        material_indices = [pre_json_material_indices[2*i_side+i] for i in range(2)]
        print(i_side)
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
                        "uvs": uvs[:3],
                        "material_index": material_indices[0]
                    },
                    {
                        "axis": tri2_axis_sign_info.axis,
                        "axis_sign": tri2_axis_sign_info.sign,
                        "vertices": verts[3:],
                        "uvs": uvs[3:],
                        "material_index": material_indices[1]
                    },
                ]
        })

    return sides


def pop_and_push_in_list(index_to_pop: int, index_to_push_to: int, list_: List):
    if index_to_pop >= len(list_):
        raise TypeError("index to pop out of bounds.")
    if index_to_push_to >= len(list_):
        raise TypeError("index to push to out of bounds.")

    popped_item: Any = list_.pop()
    list_.insert(index_to_push_to, popped_item)


class ObjectDataError(Exception):
    pass


class ObjectData:
    vertices: List[Vector]
    normals: List[Vector]
    uvs: List[Vector]
    indices: List[int]
    material_indices: List[int]
    poly_size: int

    def __init__(
            self,
            *,
            vertices: List[Vector] = [],
            normals: List[Vector] = [],
            uvs: List[Vector] = [],
            indices: List[int] = [],
            material_indices: List[int] = [],
            poly_size: int = -1
    ):
        self.vertices = vertices
        self.normals = normals
        self.uvs = uvs
        # TODO: Pretty sure indices are broken right now, since the vertices are
        #  ordered differently. See what's going on, and if required, fix.
        self.indices = indices
        self.material_indices = material_indices
        self.poly_size = poly_size

    def pop_vertex_index_and_push_to(
            self,
            index_to_pop: int,
            index_to_push_to: int,
            omit_indices: bool = False
    ):
        """Pops an item from the vertex-related lists and re-inserts it
        at a different index."""
        if not omit_indices:
            NotImplementedError("Dealing with indices isn't implemented yet.")

        for list_ in [self.vertices, self.normals, self.uvs]:
            pop_and_push_in_list(index_to_pop, index_to_push_to, list_)

    def get_face_index(
            self,
            prospective_face_vertices: List[Vector],
    ) -> int | None:
        """Returns the starting index of a face's vertex block.
        The face is identified and will be looked for based on
        the vectors in `face_vertices`.
        Returns None if there's no match."""
        poly_size = self.poly_size

        if poly_size == -1:
            raise NotImplementedError(
                "Getting the starting index of a face's vertices when "
                "poly_size is -1 (which means variable size) isn't "
                "implemented. Hint: If your object is made up of polys which "
                "are all the same size, make sure poly_size is set before "
                "calling get_face_index, e.g. by instantiating ObjectData "
                "with poly_size=3 if all polygons have a size of 3."
            )

        if not len(prospective_face_vertices) == poly_size:
            raise TypeError(
                "The number of vectors in face_vertices needs to be equal to "
                "poly_size."
            )

        # Won't properly support mesh faces that are perfectly overlapping.
        for i_face in range(int(len(self.vertices) / poly_size)):
            i_face_first_vert = i_face * poly_size
            #print(i_face, ", ", poly_size, ", ", i_face*poly_size)
            face_vertices = self.vertices[
                            i_face_first_vert:i_face_first_vert+poly_size]
            # print(
            #     "===",
            #     prospective_face_vertices,
            #     "",
            #     face_vertices,
            #     "/==="
            # )
            if all(map(
                    lambda prospective_vert: prospective_vert in face_vertices,
                    prospective_face_vertices
            )):
                return i_face_first_vert  # match!

        return None  # No match.

    def get_face_vertices_by_unordered(
            self,
            unordered_vertices: List[Vector],
    ) -> List[Vector] | None:
        face_index = self.get_face_index(
            unordered_vertices,
        )

        if face_index is None:
            return None

        return self.vertices[face_index:face_index+self.poly_size]


def debug_print_mesh_faces(mesh: BMesh, object_data: ObjectData):
    i_face = 0
    i_vert = 0
    for face in mesh.faces:
        print("Face:", i_face)

        for bmvert in face.verts:
            vert_face = bmvert_location_as_vector(bmvert)
            vert_object_data = object_data.vertices[i_vert]
            are_identical = vert_face == vert_object_data
            print("\t", vert_face, "\t|||", vert_object_data, "\t|||", "identical:", are_identical)
            i_vert += 1

        i_face += 1


class FaceCoordsBuildError(Exception):
    pass


class FaceCoords:
    uvs: Tuple[Vector]
    xyzs: Tuple[Vector]

    def __init__(self, uvs: Iterable[Vector], xyzs: Iterable[Vector]):
        self.uvs = tuple(get_frozen_vector_copy(uv) for uv in uvs)
        self.xyzs = tuple(get_frozen_vector_copy(xyz) for xyz in xyzs)

    def __eq__(self, other) -> bool:
        if isinstance(other, self.__class__):
            if self.uvs == other.uvs and self.xyzs == other.xyzs:
                return True
        return False

    def __hash__(self) -> int:
        return hash(self.uvs + self.xyzs)


class FaceCoordsBuilder:
    poly_count: int
    _uvs: List[Vector]
    _xyzs: List[Vector]
    
    def __init__(self, poly_count = 3):
        self.poly_count = poly_count
        self._uvs = []
        self._xyzs = []
        
    def add_uv(self, uv: Vector) -> "FaceCoordsBuilder":
        if len(self._uvs) >= self.poly_count:
            raise FaceCoordsBuildError(
                f"Attempted to add a UV coord (%s) beyond .poly_count (%s)." % (uv, self.poly_count),
                f"Currently held UV coords: %s." % self._uvs,
                f"Currently held XYZ coords: %s." % self._uvs

            )
        self._uvs.append(uv)
        return self
    
    def add_xyz(self, xyz: Vector) -> "FaceCoordsBuilder":
        if len(self._xyzs) >= self.poly_count:
            raise FaceCoordsBuildError(
                f"Attempted to add a UV coord (%s) beyond .poly_count (%s)." % (xyz, self.poly_count),
                f"Currently held UV coords: %s." % self._uvs,
                f"Currently held XYZ coords: %s." % self._uvs

            )
        self._xyzs.append(xyz)
        return self

    def add_uvs(self, uvs: Iterable[Vector]) -> "FaceCoordsBuilder":
        for uv in uvs:
            self.add_uv(uv)
        return self

    def add_xyzs(self, xyzs: Iterable[Vector]) -> "FaceCoordsBuilder":
        for xyz in xyzs:
            self.add_xyz(xyz)
        return self

    def get(self) -> FaceCoords:
        return FaceCoords(self._uvs, self._xyzs)


class UVToVertMapKey(NamedTuple):
    uv: Vector
    xyz: Vector


def items_in_list(list_a, list_b) -> bool:
    items_found = 0
    lower_len = min(len(list_a), len(list_b))

    for item in list_a:
        if item in list_b:
            items_found += 1

    if items_found == lower_len:
        return True

    return False


class Face:
    vertices: List[Vector]
    uvs: List[Vector]
    normals: List[Vector]
    material_index: int

    def __init__(
            self,
            vertices: List[Vector],
            uvs: List[Vector],
            normals: List[Vector],
            material_index: int
    ):
        self.vertices = vertices
        self.uvs = uvs
        self.normals = normals
        self.material_index = material_index


class RawExportError(Exception):
    pass


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
        face_vertex_count = 3

        mesh: BMesh = bmesh.new()
        obj: bpy.types.ObjectBase = bpy.context.active_object
        mesh.from_mesh(obj.data)
        uv_layer: BMLayerItem = mesh.loops.layers.uv.active

        object_data = ObjectData(poly_size=face_vertex_count)

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

        all_uv_coords: list[Vector] = get_all_uv_coords()  # They already come sorted by face.
        uv_coords_grouped_by_face: list[list[Vector]] =\
            get_equally_split_list(all_uv_coords, face_vertex_count)

        faces: List[Face] = []
        for face in mesh.faces:
            face: BMVert = face
            verts: List[Vector] = []
            uvs: List[Vector] = []
            normals: List[Vector] = []
            _vert_by_uvs: Dict[Vector, Vector] = {}

            for vert in face.verts:
                verts.append(bmvert_location_as_vector(vert))
                normals.append(vert.normal)

                for loop in vert.link_loops:
                    if loop.face == face:
                        uvs.append(loop[uv_layer].uv)

            faces.append(Face(verts, uvs, normals, face.material_index))

        for _face in faces:
            print("FACE:")
            print(_face.vertices)
            print(_face.uvs)
            print(_face.material_index)

        for face in faces:
            face: Face = face
            object_data.vertices = object_data.vertices + face.vertices
            object_data.normals = object_data.normals + face.normals
            object_data.uvs = object_data.uvs + face.uvs
            object_data.indices = []
            object_data.material_indices.append(face.material_index)

        mesh_pre_json = {
            "vertices": object_data.vertices,
            "normals": object_data.normals,
            "uvs": object_data.uvs,
            "indices": object_data.indices,
            "material_indices": object_data.material_indices,
            # List version of `materials`.
            "materials": [
                materials_pre_json[index] for index in range(material_index)
            ]
        }

        pprint.pprint(generate_cube_debug_side_list(mesh_pre_json), indent=4)
        print(mesh_pre_json["material_indices"])

        with open(DEVFIXTURE_output_path, "w") as output_file:
            output_file.write(json.dumps(mesh_pre_json, cls=AllJSONEncoders, indent=4))

        return {"FINISHED"}


def register():
    bpy.utils.register_class(RawExport)


def unregister():
    bpy.utils.unregister_class(RawExport)
