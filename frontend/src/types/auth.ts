export interface LoginRequest {
  username: string
  password: string
}

export interface LoginSession {
  token: string
  userId: number
  username: string
  roles: string[]
}

export interface UserProfile {
  id: number
  username: string
  nickname: string | null
  email: string | null
  phone: string | null
  status: string
  roles: string[]
  permissions: string[]
}
