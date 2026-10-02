@{
from rosidl_parser.definition import AbstractGenericString
from rosidl_parser.definition import BasicType
}@

@# #################################################
@# ############ Idiomatic message types ############
@# #################################################
@# These types use standard Rust containers where possible.
@[for subfolder, msg_spec in msg_specs]@
@{
type_name = msg_spec.structure.namespaced_type.name
package_path = "super::super" if representation == "buffer" else "super"
}@

// Corresponds to @(package_name)__@(subfolder)__@(type_name)
@{comments = msg_spec.structure.get_comment_lines()}@
@[for line in comments]@
@[  if line]@
/// @(line)
@[  else]@
///
@[  end if]@
@[end for]@
@[if not comments]
// This struct is not documented.
#[allow(missing_docs)]
@[end if]@

@# Leading underscores imply an unused symbol, skip it.
@[if "_" in type_name[1:]]@
#[allow(non_camel_case_types)]
@[end if]@
#[cfg_attr(feature = "serde", derive(Deserialize, Serialize))]
#[derive(Clone, Debug, PartialEq, PartialOrd)]
pub struct @(type_name) {
@[for member in msg_spec.structure.members]@
@{
comments = member.get_comment_lines()
}@
@[  for line in comments]@
@[    if line]@
    /// @(line)
@[    else]@
    ///
@[    end if]@
@[  end for]@
@[  if not comments]
    // This member is not documented.
    #[allow(missing_docs)]
@[  end if]@
    @(pre_field_serde(member.type))pub @(get_rs_name(member.name)): @(get_public_rs_type(member.type, representation)),

@[end for]@
}

@[if msg_spec.constants]@
impl @(type_name) {
@[for constant in msg_spec.constants]@
@{
comments = getattr(constant, 'get_comment_lines', lambda: [])()
}@
@[  for line in comments]@
@[    if line]@
    /// @(line)
@[    else]@
    ///
@[    end if]@
@[  end for]@
@[  if not comments]
    // This constant is not documented.
    #[allow(missing_docs)]
@[  end if]@
@[  if isinstance(constant.type, BasicType)]@
    pub const @(get_rs_name(constant.name)): @(get_public_rs_type(constant.type, representation)) = @(constant_value_to_rs(constant.type, constant.value));

@[  elif isinstance(constant.type, AbstractGenericString)]@
    pub const @(get_rs_name(constant.name)): &'static str = @(constant_value_to_rs(constant.type, constant.value));

@[  else]@
@{assert False, 'Unhandled constant type: ' + str(constant.type)}@
@[  end if]@
@[end for]@
}
@[end if]

impl Default for @(type_name) {
    fn default() -> Self {
@#  This has the benefit of automatically setting the right default values
        <Self as rosidl_runtime_rs::Message>::from_rmw_message(Default::default())
    }
}

impl rosidl_runtime_rs::Message for @(type_name) {
    type RmwMsg = @(package_path)::@(subfolder)::rmw::@(type_name);

    fn into_rmw_message(msg_cow: std::borrow::Cow<'_, Self>) -> std::borrow::Cow<'_, Self::RmwMsg> {
        match msg_cow {
            std::borrow::Cow::Owned(msg) => std::borrow::Cow::Owned(Self::RmwMsg {
@[for member in msg_spec.structure.members]@
                @(get_rs_name(member.name)): @(public_conversion(member.type, 'msg.' + get_rs_name(member.name), representation, 'to')),
@[end for]@
            }),
            std::borrow::Cow::Borrowed(msg) => std::borrow::Cow::Owned(Self::RmwMsg {
@[for member in msg_spec.structure.members]@
                @(get_rs_name(member.name)): @(public_conversion(member.type, '&msg.' + get_rs_name(member.name), representation, 'to', True)),
@[end for]@
            }),
        }
    }

    fn from_rmw_message(msg: Self::RmwMsg) -> Self {
        Self::try_from_rmw_message(msg).expect("message conversion failed")
    }

    fn try_from_rmw_message(msg: Self::RmwMsg) -> Result<Self, rosidl_runtime_rs::BufferError> {
@[if representation == 'cpu']@
        let msg = rosidl_runtime_rs::RmwMessage::try_into_cpu(msg)?;
@[end if]@
        Ok(Self {
@[for member in msg_spec.structure.members]@
            @(get_rs_name(member.name)): @(public_conversion(member.type, 'msg.' + get_rs_name(member.name), representation, 'from')),
@[end for]@
        })
    }
}

@[if representation == 'buffer']@
impl @(type_name) {
    /// Copies accelerator fields into the CPU message representation.
    pub fn try_into_cpu(self) -> Result<@(package_path)::@(subfolder)::@(type_name), rosidl_runtime_rs::BufferError> {
        use rosidl_runtime_rs::Message;
        @(package_path)::@(subfolder)::@(type_name)::try_from_rmw_message(
            Self::into_rmw_message(std::borrow::Cow::Owned(self)).into_owned())
    }
}
impl From<@(package_path)::@(subfolder)::@(type_name)> for @(type_name) {
    fn from(message: @(package_path)::@(subfolder)::@(type_name)) -> Self {
        use rosidl_runtime_rs::Message;
        Self::from_rmw_message(@(package_path)::@(subfolder)::@(type_name)::into_rmw_message(
            std::borrow::Cow::Owned(message)).into_owned())
    }
}
@[end if]@
@[end for]@
