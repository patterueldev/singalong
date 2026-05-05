interface ErrorMessageProps {
  error: Error | null
  onDismiss?: () => void
}

export const ErrorMessage = ({ error, onDismiss }: ErrorMessageProps) => {
  if (!error) return null

  return (
    <div className="error-message">
      <p>{error.message}</p>
      {onDismiss && (
        <button onClick={onDismiss} className="error-dismiss">
          Dismiss
        </button>
      )}
    </div>
  )
}
