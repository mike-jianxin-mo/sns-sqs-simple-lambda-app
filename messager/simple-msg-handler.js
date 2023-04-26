exports.msg_handler = async (event, context) => {
  const message = event.Records[0].body;

  console.log(`Received message: ${message}`);

  // Your code logic goes here to handle the message

  return "Message processed successfully";
};
