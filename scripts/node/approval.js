#!/usr/bin/node

const args = process.argv.slice(2);
const commentsPath = args[0];

const rejectTreshold = args.length > 1 ? args[1] : undefined;
const approveThreshold = args.length > 2 ? args[2] : undefined;

const fs = require('fs');

let comments;
try {
	comments = JSON.parse(fs.readFileSync(commentsPath, 'utf8'));
} catch (err) {
	console.error(err);
}

let commentCount = 0;
let maxSeverity = 0;
let needsRework = 0;
comments.forEach((comment) => {
	let severity = parseInt(comment.severity);
	commentCount++;
	if (severity > maxSeverity) {
		maxSeverity = severity;
	}
	if (rejectTreshold && severity >= rejectTreshold) {
		needsRework++;
	}
});

let reviewEvent = 'COMMENT';
let reviewText = 'Salesforce Code Analyzer did not find any rule violations';
if (approveThreshold && maxSeverity <= approveThreshold) {
	reviewEvent = 'APPROVE';
	if (commentCount > 0) {
		reviewText = `Maximum severity of the ${commentCount} rule violations identified by the Salesforce Code Analyzer was ${maxSeverity}.`;
	}
} else if (commentCount > 0 && rejectTreshold && maxSeverity >= rejectTreshold) {
	reviewEvent = 'REQUEST_CHANGES';
	reviewText = `At least ${needsRework} of the ${commentCount} rule violations identified by the Salesforce Code Analyzer require rework. Max severity found: ${maxSeverity}. `;
} else if (commentCount > 0) {
	reviewText = `Salesforce Code Analyzer identified ${commentCount} rule violations in your changes with severity as high as: ${maxSeverity}. `;
}

fs.writeFileSync('reviewEvent.txt', reviewEvent);
fs.writeFileSync('reviewBody.txt', reviewText);
