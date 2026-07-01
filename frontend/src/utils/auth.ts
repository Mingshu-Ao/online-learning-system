const TOKEN_KEY = 'online-learning-token'

export function getStoredToken(): string {
  if (typeof window === 'undefined') {
    return ''
  }
  return window.localStorage.getItem(TOKEN_KEY) ?? ''
}

export function setStoredToken(token: string) {
  if (typeof window === 'undefined') {
    return
  }
  window.localStorage.setItem(TOKEN_KEY, token)
}

export function clearStoredToken() {
  if (typeof window === 'undefined') {
    return
  }
  window.localStorage.removeItem(TOKEN_KEY)
}
