/**
 * A Lambda function that returns a static string
 */
console.log("Loading function");
import AWS from "aws-sdk";

export const triggerSNSEvent = async (event, context) => {
  var eventText = JSON.stringify(event, null, 2);
  console.log("Received event:", eventText);
  var sns = new AWS.SNS();
  var params = {
    Message: eventText,
    Subject: "Test SNS From Lambda",
    TopicArn:
      "arn:aws:sns:ap-southeast-1:236353575297:simple-sns-sqs-msg-sns-topic",
  };
  console.log("Sending notifications ...");
  console.log(params);
  // const r = await sns.publish(params, context.done);
  // console.log(r);

  sns
    .publish(params, context.done)
    .promise()
    .then((data) => {
      console.log("Success!!");
      console.log(data); // This will log the response data from the SNS publish action
    })
    .catch((err) => {
      console.log("Failed!!");
      console.error(err, err.stack); // An error occurred
    });
};
