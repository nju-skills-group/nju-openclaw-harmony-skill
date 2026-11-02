export interface Track {
  name: string;
  singer: string;
  duration: number;
}

export interface PlayResult {
  tracks: Track[];
}

export interface PlaybackResult {
  action: string;
  status: string;
  playingTrack?: Track;
}

/**
 * Minimal in-memory business-service stand-in for the official Skill example.
 * It demonstrates the Skill-to-business-module boundary; it does not play audio.
 */
export class MusicPlayer {
  private static readonly tracks: Track[] = [
    { name: 'SongA', singer: 'SingerA', duration: 269 },
    { name: 'SongB', singer: 'SingerB', duration: 214 },
    { name: 'SongC', singer: 'SingerA', duration: 301 }
  ];

  private static currentTrack: Track | undefined = undefined;
  private static playbackStatus: string = 'stopped';
  private static currentIndex: number = -1;

  public static searchAndPlay(songName: string, singer: string): PlayResult | null {
    const normalizedSong: string = songName.toLocaleLowerCase();
    const normalizedSinger: string = singer.toLocaleLowerCase();
    const matches: Track[] = this.tracks.filter((track: Track) => {
      const songMatches: boolean = normalizedSong.length === 0 ||
        track.name.toLocaleLowerCase().includes(normalizedSong);
      const singerMatches: boolean = normalizedSinger.length === 0 ||
        track.singer.toLocaleLowerCase().includes(normalizedSinger);
      return songMatches && singerMatches;
    });

    if (matches.length === 0) {
      return null;
    }

    this.currentTrack = matches[0];
    this.currentIndex = this.tracks.indexOf(matches[0]);
    this.playbackStatus = 'playing';
    return { tracks: matches };
  }

  public static controlPlayback(action: string): PlaybackResult | null {
    if (this.currentTrack === undefined) {
      return null;
    }

    if (action === 'pause') {
      this.playbackStatus = 'paused';
    } else if (action === 'resume') {
      this.playbackStatus = 'playing';
    } else if (action === 'next' || action === 'previous') {
      const step: number = action === 'next' ? 1 : -1;
      this.currentIndex = (this.currentIndex + step + this.tracks.length) % this.tracks.length;
      this.currentTrack = this.tracks[this.currentIndex];
      this.playbackStatus = 'playing';
    } else {
      return null;
    }

    return {
      action: action,
      status: this.playbackStatus,
      playingTrack: this.currentTrack
    };
  }
}
