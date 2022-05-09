#!/usr/bin/node

const args = process.argv.slice(2);
const filePath = args[0];
const commentsPath = args[1];

const rejectTreshold = args.length > 2 ? args[2] : undefined;
const approveThreshold = args.length > 3 ? args[3] : undefined;

const fs = require('fs');

let lineDiffData;
let comments;
try {
	lineDiffData = fs.readFileSync(filePath, 'utf8');
	comments = JSON.parse(fs.readFileSync(commentsPath, 'utf8'));
} catch (err) {
	console.error(err);
}

function getLineToPositionMaps(diffLines) {
	let lines = diffLines.split('\n');
	let fileToLineMaps = new Map();
	let currentFileName;
	let currentIndex = 4; //diff hunk shows 2 lines before the change
	lines.forEach((oneLine) => {
		let fileAndLines = oneLine.split(':');
		let linesInHunk;
		let fileLineMap;
		if (fileAndLines.length === 2) {
			//new file
			currentFileName = fileAndLines[0];
			currentIndex = 4; //diff hunk shows 2 lines before the change
			linesInHunk = fileAndLines[1].split(',');
			fileLineMap = new Map();
		} else {
			//lines from next hunk
			currentIndex++; //diff hunk shows 1 line after the change
			linesInHunk = fileAndLines[0].split(',');
			fileLineMap = fileToLineMaps.get(currentFileName);
		}

		linesInHunk.forEach((lineNumber) => {
			console.log(currentFileName + ' - ' + lineNumber);
			let lineNumberInteger = parseInt(lineNumber);
			if (lineNumberInteger) {
				fileLineMap.set(lineNumberInteger, currentIndex++);
			}
		});
		fileToLineMaps.set(currentFileName, fileLineMap);
	});

	return fileToLineMaps;
}

function filterAndTranslatePositionReviewComments(allComments, positionMaps) {
	let relevantComments = [];

	allComments.forEach((comment) => {
		console.log(comment);
		let line = parseInt(comment.position);
		let filename = comment.path;
		if (!positionMaps.has(filename)) {
			console.warn(`${filename} not in git diff`);
			return;
		}
		let lineToPosition = positionMaps.get(filename);
		console.log(lineToPosition);
		if (!lineToPosition.has(line)) {
			console.warn(`line ${line} is not in git diff for ${filename}`);
			return;
		}
		comment.position = lineToPosition.get(line);
		relevantComments.push(comment);
	});
	return relevantComments;
}

let lineMaps = getLineToPositionMaps(lineDiffData);
console.log(lineMaps);
let relevantComments = filterAndTranslatePositionReviewComments(comments, lineMaps);

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
	delete comment.severity;
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
	reviewText = `At least ${needsRework} of the ${commentCount} rule violations identified by the Salesforce Code Analyzer require rework. Highest severity found was ${maxSeverity}. `;
} else if (commentCount > 0) {
	reviewText = `Salesforce Code Analyzer identified ${commentCount} rule violations in your changes with severity as high as ${maxSeverity}. `;
}

fs.writeFileSync('reviewEvent.txt', reviewEvent);
fs.writeFileSync('reviewBody.txt', reviewText);

fs.writeFileSync(commentsPath, JSON.stringify(relevantComments));
