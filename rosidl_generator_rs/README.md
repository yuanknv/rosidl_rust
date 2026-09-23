# rosidl_generator_rs

Each IDL interface generates a CPU representation and an opt-in buffer
representation with the same ROS type support:

```rust
use sensor_msgs::msg::{Image, buffer};

let cpu = Image { data: vec![1, 2, 3], ..Default::default() };
let image = buffer::Image::from(cpu);
assert_eq!(image.data.as_slice(), Some(&[1, 2, 3][..]));
```

`msg::Image` retains ordinary CPU fields. `msg::buffer::Image` stores primitive
sequences in `Buffer<T>` and nested messages in their buffer representations.
Bounded sequences retain their IDL bounds. `srv::buffer` and `action::buffer`
provide equivalent service and action types. Generated modules also work through
`ros_env`.

Both representations implement `Message` with the same `RmwMsg`. Each publisher
publishes a sample once; CPU and buffer subscriptions can consume the same topic.
CPU callbacks receive host values. Buffer callbacks can inspect `backend_name`,
copy through `to_vec`, or borrow device data through an installed adapter.

Subscriptions accept CPU storage by default. Accelerator consumers opt in with
`SubscriptionOptions::acceptable_buffer_backends("cuda")`. CPU remains a
transport fallback. Allocation and device access belong to the accelerator
adapter; generated message types contain storage and conversions.

Owned buffer-to-RMW conversion preserves the native owner. Cloning and borrowed
publication can copy data; CPU conversion and serde can copy device data to host.
`try_into_cpu` reports transfer failures. Service requests/responses and action
goals/feedback/results are materialized on the CPU before serialization; they
do not use accelerator IPC. The native C/Rust transport layouts
must be rebuilt together.
