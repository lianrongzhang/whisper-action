# whisper-action

Speech-to-Text using [ggerganov/whisper.cpp](https://github.com/ggerganov/whisper.cpp) for [GitHub Action](https://github.com/features/actions). High-performance inference of OpenAI Whisper automatic speech recognition (ASR) model.

## Inputs variables

See [action.yml](./action.yml) for more detailed information.

| Variable         | Description                                                  | Default |
|------------------|--------------------------------------------------------------|---------|
| model            | public whisper model. (available: small, medium and large)   | small   |
| audio_path       | Audio Path.                                                  |         |
| output_folder    | output folder.                                               |         |
| output_format    | output format, support txt, srt, csv.                        | txt     |
| output_filename  | output filename.                                             |         |
| debug            | enable debug mode.                                           |         |
| print_progress   | print progress.                                              | true    |
| print_segment    | print segment.                                               |         |
| youtube_url      | youtube url                                                  |         |
| video_list_file  | path to JSON file containing video list with video_id fields|         |
| translate        | translate from source language to english.                   | false   |
| cut_silences     | cut silences.                                                | false   |
| prompt           | initial prompt text.                                         |         |

## Usage

### Single Video

Download Youtube video and transcript it.

```yaml
jobs:
  youtube-eng-video:
    name: transcript english video
    runs-on: ubuntu-latest
    steps:
    - name: checkout
      uses: actions/checkout@v3

    - name: speech to text
      uses: appleboy/whisper-action@v0.1.1
      with:
        model: small
        youtube_url: https://www.youtube.com/watch?v=pTCxXZh6VyE
        output_format: srt
        output_folder: youtube
        print_segment: true
        debug: true

    - name: git push changes
      uses: appleboy/git-push-action@v0.0.2
      with:
        branch: main
        commit: true
        commit_message: "[skip ci] Upload changes"
        remote: git@github.com:appleboy/whisper-action.git
        ssh_key: ${{ secrets.DEPLOY_KEY }}
        rebase: true
```

### Batch Processing Multiple Videos

Process multiple videos from a JSON file containing video IDs.

First, create a JSON file (e.g., `video_list.json`) with the following format:

```json
{
  "summary": {
    "total_videos_scanned": 3,
    "total_selected_videos": 3
  },
  "videos": [
    {
      "channel": "Channel Name",
      "video_id": "pTCxXZh6VyE",
      "title": "Video Title 1"
    },
    {
      "channel": "Channel Name",
      "video_id": "M_bjhKtR3fs",
      "title": "Video Title 2"
    }
  ]
}
```

Then use the `video_list_file` parameter in your workflow:

```yaml
jobs:
  batch-process-videos:
    name: transcript multiple videos
    runs-on: ubuntu-latest
    steps:
    - name: checkout
      uses: actions/checkout@v3

    - name: speech to text for multiple videos
      uses: appleboy/whisper-action@v0.1.1
      with:
        model: small
        video_list_file: video_list.json
        output_format: txt,srt,csv
        output_folder: youtube
        print_segment: true
        debug: true

    - name: git push changes
      uses: appleboy/git-push-action@v0.0.2
      with:
        branch: main
        commit: true
        commit_message: "[skip ci] Upload transcriptions"
        remote: git@github.com:appleboy/whisper-action.git
        ssh_key: ${{ secrets.DEPLOY_KEY }}
        rebase: true
```

The action will automatically read the `video_id` field from each video in the JSON file and process them sequentially.

See the output file in youtube folder.
