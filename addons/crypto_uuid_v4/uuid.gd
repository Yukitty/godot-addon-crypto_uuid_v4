tool
class_name UUID
extends Resource
# Crypto UUID v4
#
# Provides cryptographically secure UUID v4 objects.
# Can be used and compared in string format,
# or as persistent UUID resource objects.
#
# See https://github.com/Yukitty/godot-addon-crypto_uuid_v4/
# for usage details.


export var string : String


func _init(from = null) -> void:
	resource_name = "UUID"
	if from is PoolByteArray:
		assert(from.size() == 16)
		string = format(from)
	elif from is String:
		assert(from.length() == 36)
		string = from
	else:
		string = v4()
	assert(is_valid(string))
	resource_name = "UUID:" + string


# The string is just the UUID
func _to_string() -> String:
	return string


# Returns true if UUID string passes basic sanity tests
static func is_valid(uuid : String) -> bool:
	return uuid.length() == 36 and uuid[8] == '-' and uuid[13] == '-' and uuid[18] == '-' and uuid[23] == '-' and _hex_byte(uuid, 14) & 0xf0 == 0x40 and _hex_byte(uuid, 19) & 0xc0 == 0x80


# Compare a UUID object with another UUID, String, or PoolByteArray.
func is_equal(object) -> bool:
	# Compare UUID objects
	if object is Resource and get_script().instance_has(object):
		return string == object.string

	# Compare to raw UUID data
	if object is PoolByteArray:
		if object.size() != 16:
			return false
		return string == format(object)

	# Compare strings
	return string == str(object)


# Convinience func
static func v4() -> String:
	return format(v4bin())


# Generate efficient binary representation
# Returns PoolByteArray[16] of cryptographically-secure (if available)
# random bytes with a UUID v4 compatible signature.
static func v4bin() -> PoolByteArray:
	var data: PoolByteArray

	if OS.has_feature("web"):
		# Fallback for HTML5 export
		if OS.has_feature("JavaScript"):
			# Rely on browser's Crypto object if available
			var output = JavaScript.eval("window.crypto.getRandomValues(new Uint8Array(16));")
			if output is PoolByteArray and output.size() == 16:
				data = output

		if not data:
			# Generate weak random values
			# ONLY as a last resort,
			# when Crypto is not provided by the browser
			var rng := RandomNumberGenerator.new()
			rng.randomize()
			data = PoolByteArray([
				_randb(rng), _randb(rng), _randb(rng), _randb(rng),
				_randb(rng), _randb(rng), _randb(rng), _randb(rng),
				_randb(rng), _randb(rng), _randb(rng), _randb(rng),
				_randb(rng), _randb(rng), _randb(rng), _randb(rng)
			])

	else:
		# Use cryptographically secure bytes when available
		data = Crypto.new().generate_random_bytes(16)

	data[6] = (data[6] & 0x0f) | 0x40
	data[8] = (data[8] & 0x3f) | 0x80
	return data

# Format any 16 bytes as a UUID.
static func format(data: PoolByteArray) -> String:
	assert(data.size() == 16)
	return '%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x' % (data as Array)


# Private helper func
static func _randb(rng) -> int:
	return rng.randi_range(0x00,0xff)


static func _hex_byte(text: String, offset: int) -> int:
	return ("0x" + text.substr(offset, 2)).hex_to_int()
