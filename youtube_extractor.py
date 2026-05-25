import os
import cv2
import subprocess

def extract_youtube_frames(url, start_time, duration, output_dir):
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    print(f"Downloading video from {url}...")
    
    # Use the standalone yt-dlp.exe
    cmd = [
        "yt-dlp.exe",
        "-f", "best[ext=mp4]",
        "-o", "temp_video.%(ext)s",
        "--no-playlist",
        url
    ]
    
    subprocess.run(cmd, check=True)
        
    print("Download complete. Extracting frames...")
    
    cap = cv2.VideoCapture("temp_video.mp4")
    
    # Get video FPS to calculate frame numbers
    fps = cap.get(cv2.CAP_PROP_FPS)
    start_frame = int(start_time * fps)
    end_frame = int((start_time + duration) * fps)
    
    cap.set(cv2.CAP_PROP_POS_FRAMES, start_frame)
    
    frame_count = 0
    saved_count = 0
    
    while cap.isOpened() and cap.get(cv2.CAP_PROP_POS_FRAMES) <= end_frame:
        ret, frame = cap.read()
        if not ret:
            break
            
        # Save every 2nd frame to avoid too many images (approx 15fps if original is 30)
        if frame_count % 2 == 0:
            frame_path = os.path.join(output_dir, f"frame_{saved_count:04d}.png")
            cv2.imwrite(frame_path, frame)
            saved_count += 1
            
        frame_count += 1
        
    cap.release()
    if os.path.exists("temp_video.mp4"):
        os.remove("temp_video.mp4")
        
    print(f"Extraction complete! Saved {saved_count} frames to {output_dir}")

if __name__ == "__main__":
    url = "https://www.youtube.com/watch?v=IWFyJ_IifjY"
    # Target time is 1:45 (105s). Extract from 105 to 110s.
    extract_youtube_frames(url, 105, 5, "youtube_frames_1080p")
